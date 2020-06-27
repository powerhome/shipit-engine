# Review Stacks

A Review Stack is a dynamically managed stack whose lifecycle is tied to a Github Pull Request.

# Enabling Review Stacks

Review stacks can be enabled via the shipit-engine Repository UI.

1. Visit the shipit-engine Repository UI - `https://host-application/repositories`
1. Click on the project's repository
1. Check "Dynamically provision stacks for Pull Requests?"
1. Select the "Provisioning Behavior" appropriate for your project - most likely "Allow All"
1. Click "Save"

# Configuring Review Stack behavior

shipit-engine support three distinct behaviors for determining which Pull Requests should be considered for Review Stack creation.

1. "Allow All" - shipit-engine will create a Review Stack for every new Pull Requests.
1. "Allow With Label" - when creating or updating a Pull Request, the user must add a label matching the `Shipit::Repository`'s "provisioning_label" attribute in order for shipit-engine to dynamically create/manage a Review Stack - an opt-in strategy.
1. "Prevent With Label" - when creating or updating a Pull Request, the user must add a label matching the `Shipit::Repository`'s "provisoining_label" attribute in order to **prevent** shipit-engine from dynamically creating/managing a Review Stack - an opt-out strategy.

# Provisioning and deprovisioning Review Stack environments

Review Stacks will need an environment into which they are deployed. For some this might be a Heroku instance, for others it might be a Kubernetes namespace, etc. shipit-engine allows the host application to define `ProvisioningHandler`s to define how Review Stacks should provisoin/deprovision their environments.

For example, imagine a repository which deploys to a Kubernetes cluster. The host application could register a Kubernetes provisioning handler to take care of creating / destroying kubernetes resources for a stack:

Define a provisioning Handler

```ruby
class KubernetesProvisioningHandler < Shipit::ProvisioningHandler::Base
  def up
    # allocate a namespace, copy resources, etc
  end

  def down
    # delete the namespace, etc.
  end
end
```

Register a default provisioning handler - IE how repositories which don't explicitly define a provisoining handler will be provisioned:

```ruby
Shipit::ProvisioningHandler.register(:default, KubernetesProvisioningHandler)
```

Or, define a provisionng handler for a specific repository:

```ruby
Shipit::ProvisioningHandler.register('powerhome/nitro-web', KubernetesProvisioningHandler)
```

Repository specific `ProvisioningHandler`s can also be configured in the project's `shipit.yml` by supplying the name of the provisioning handler supplied by the host application. For example:

```yaml
provision:
  handler_name: KubernetesProvisioningHandler

deploy:
  override: <deployment-script>
```

A default, no-op provisioning handler is provided when neither a repository level, nor host-application-default provisioning handler is provided.

The Provisioner for a given stack is discovered at runtime using the following order of precedence:

1. shipit.yml - `handler_name:` value
1. repository name - `Shipit::ProvisioningHandler.register(<stack's github_repo_name>, ...)`
1. default override - `Shipit::ProvisioningHandler.register(:default, ...)`
1. no-op default - `ProvisioningHandler::Base`
