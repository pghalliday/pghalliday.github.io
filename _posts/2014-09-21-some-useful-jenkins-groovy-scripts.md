---
layout: post
title:  "Some useful Jenkins Groovy scripts"
categories: Jenkins Groovy Sonar Chef configuration management
disqus_identifier: some-useful-jenkins-groovy-scripts
---

Recently I needed to automate the deployment and configuration of a [Jenkins][jenkins] server. My configuration management tool of choice is [Chef][chef] and my starting point is the [Opscode Jenkins cookbook][jenkins-cookbook]. At this time the Jenkins cookbook only provides resources for basic Jenkins configuration, eg. `jenkins_user`, however it also exposes the `jenkins_script` resource for running arbitrary [Groovy][groovy] scripts on the server.

Using Groovy it's possible to configure pretty much every part of a Jenkins server and even its plugins. However, finding documentation on how is not so trivial - the best place to start is the [Jenkins Javadocs][jenkins-api].

All of the following scripts were run with the `jenkins_script` resource as follows

```ruby
jenkins_script 'resource name' do
  command <<-EOH.gsub(/^ {4}/, '')
    [Groovy Script]
  EOH
end
```

It should also be noted that although it might be possible to write idempotent Groovy scripts the following are not exactly idempotent (although they can mostly be run as many times as you like without messing up the configuration)

Setting permissions
-------------------

The first thing I needed to do was configure user permisssions so that only a user called `admin` could access anything. Note that the following script assumes that an `admin` user has been added already. Also in the context of a Chef run, immediately after running this, Chef will no longer be able to run scripts on the server unless it uses a private key that has been associated with the `admin` user (the solution to this problem is given in the [appendix](#appendix)).

```groovy
import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
instance.setSecurityRealm(hudsonRealm)

def strategy = new GlobalMatrixAuthorizationStrategy()
strategy.add(Jenkins.ADMINISTER, "admin")
instance.setAuthorizationStrategy(strategy)

instance.save()
```

Set the slave agent port
------------------------

By default the jenkins slave agent port is randomized. However in my case I needed to configure my cluster using a firewall on the Jenkins master and thus wanted to open a single port to use for build slaves to communicate with the master using JNLP.

```groovy
import jenkins.model.*

def instance = Jenkins.getInstance()

instance.setSlaveAgentPort([the fixed port number])

instance.save()
```

Set the administrator email address
-----------------------------------

This is the `System Admin e-mail address` set in the Jenkins configuration

```groovy
import jenkins.model.*

def jenkinsLocationConfiguration = JenkinsLocationConfiguration.get()

jenkinsLocationConfiguration.setAdminAddress("[your admin name] <[your admin email address]>")

jenkinsLocationConfiguration.save()
```

Set the mail server configuration
---------------------------------

I need the Jenkins server to mail notifications so I need to configure an SMTP server for it to use

```groovy
import jenkins.model.*

def inst = Jenkins.getInstance()

def desc = inst.getDescriptor("hudson.tasks.Mailer")

desc.setSmtpAuth("[SMTP user]", "[SMTP password]")
desc.setReplyToAddress("[reply to email address]")
desc.setSmtpHost("[SMTP host]")
desc.setUseSsl([true or false to use SLL])
desc.setSmtpPort("[SMTP port]")
desc.setCharset("[character set]")

desc.save()
```

Set the Git plugin configuration
--------------------------------

The git client used by Jenkins should have a user name and email set

```groovy
import jenkins.model.*

def inst = Jenkins.getInstance()

def desc = inst.getDescriptor("hudson.plugins.git.GitSCM")

desc.setGlobalConfigName("[name to use with git commits]")
desc.setGlobalConfigEmail("[email to use with git commits]")

desc.save()
```

Sonar plugin configuration
--------------------------

We use Sonar to run static analysis on code and record code coverage, etc. As such I needed to configure both a Sonar installation and a default Sonar runner for Jenkins to use. Javadocs for the Sonar plugin were not so easy to track down and when I did they were not so accurate so some of this was arrived at through trial and error. The best reference however, is the [Sonar plugin source][sonar-plugin] itself.

### Add the Sonar installation

```groovy
import jenkins.model.*
import hudson.plugins.sonar.*
import hudson.plugins.sonar.model.*

def inst = Jenkins.getInstance()

def desc = inst.getDescriptor("hudson.plugins.sonar.SonarPublisher")

def sinst = new SonarInstallation(
  "[name of the sonar installation - I use the host name]",
  [true or false to disable the sonar installation],
  "[sonar server url]",
  "[sonar database url]",
  "[sonar database driver]",
  "[sonar database user]",
  "[sonar database password]",
  "[version of sonar maven plugin - I don't use maven so leave this blank]",
  "[additional properties to pass to maven - again I leave this blank]",
  new TriggersConfig(),
  "[sonar user]",
  "[sonar password]"
)
desc.setInstallations(sinst)

desc.save()
```

### Add the Sonar runner

This adds a runner that will be installed automatically from Maven central

```groovy
import jenkins.model.*
import hudson.plugins.sonar.*
import hudson.tools.*

def inst = Jenkins.getInstance()

def desc = inst.getDescriptor("hudson.plugins.sonar.SonarRunnerInstallation")

def installer = new SonarRunnerInstaller("[sonar runner version]")
def prop = new InstallSourceProperty([installer])
def sinst = new SonarRunnerInstallation("[name of the sonar runner - I called it Default]", "[home? - not sure how this is used and I left it blank]", [prop])
desc.setInstallations(sinst)

desc.save()
```

Set the number of executors
---------------------------

As I was building a Jenkins cluster I wanted all my builds to run on slaves and as such the master should have 0 executors. This was the only problem script as it requires a Jenkins restart to apply. I didn't want Jenkins to restart everytime the chef client run (there's that idempotence problem) so had to wrap this with a flag to ensure it only ran on the first Chef run.

```groovy
import jenkins.model.*

def instance = Jenkins.getInstance()

instance.setNumExecutors(0)

instance.save()
```

and wrapped as follows

```ruby
jenkins_script 'master should have 0 executors' do
  command <<-EOH.gsub(/^ {4}/, '')
    import jenkins.model.*

    def instance = Jenkins.getInstance()

    instance.setNumExecutors(0)

    instance.save()
  EOH
  notifies :create, 'ruby_block[set the executors_set flag]', :immediately
  notifies :restart, 'service[jenkins]', :delayed
  not_if { node.attribute?('executors_set') }
end

ruby_block 'set the executors_set flag' do
  block do
    node.set['executors_set'] = true
    node.save
  end
  action :nothing
end
```

Appendix
--------

Here's how to add a Jenkins user with Chef and the Jenkins cookbook such that once the user and key has been added, Chef then uses that key for future communication with the server.

```ruby
# If security was enabled in a previous chef run then set the private key in the run_state
# now as required by the Jenkins cookbook
ruby_block 'set jenkins private key' do
  block do
    node.run_state[:jenkins_private_key] = '[your private key]'
  end
  only_if { node.attribute?('security_enabled') }
end

# Add the admin user only if it has not been added already then notify the resource
# to set the security_enabled flag and update the run_state
jenkins_user 'admin' do
  password '[your admin password]'
  public_keys ['[your public key]']
  notifies :create, 'ruby_block[set the security_enabled flag]', :immediately
  not_if { node.attribute?('security_enabled') }
end

# Set the security enabled flag and set the run_state to use the configured private key
ruby_block 'set the security_enabled flag' do
  block do
    node.run_state[:jenkins_private_key] = '[your private key]'
    node.set['security_enabled'] = true
    node.save
  end
  action :nothing
end
```

[jenkins]: http://jenkins-ci.org/
[jenkins-cookbook]: https://github.com/opscode-cookbooks/jenkins
[chef]: https://www.getchef.com/
[sonar]: http://www.sonarqube.org/
[groovy]: http://groovy.codehaus.org/
[jenkins-api]: http://javadoc.jenkins-ci.org/
[sonar-plugin]: https://github.com/SonarSource/jenkins-sonar-plugin
