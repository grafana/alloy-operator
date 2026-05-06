# Changelog

## 0.5.7

* Update Alloy Operator base image to operator-framework/helm-operator:v1.42.2 (@petewall)
* Update Alloy to 1.8.1 (@petewall)

## 0.5.6

* Replace wildcard (`*`) verbs in the alloy-objects RBAC rules with an explicit verb list. The rendered ClusterRole/Role no longer grants `impersonate` (or any future verbs Kubernetes adds) on `rbac.authorization.k8s.io` resources. `bind` and `escalate` are still granted because the operator needs them to create the ClusterRoles/RoleBindings that managed Alloy instances require (@petewall)

## 0.5.5

* Update Alloy to 1.8.0 (@petewall)

## 0.5.4

* Add support for global.imagePullPolicy (@petewall)

## 0.5.3

* Update Alloy to 1.7.0 (@petewall)
* Add support for PodDisruptionBudget and topologySpreadConstraints (@petewall)
* Add the ability to use global.imageRegistry instead of global.image.registry (@petewall)

## 0.5.2

* Update Alloy to 1.6.2 (@petewall)

## 0.5.0

* Add the ability to override the deployment namespace (@petewall)
* Update Alloy to 1.6.1 (@petewall)

## 0.4.2

* Update Alloy to 1.6.0 (@petewall)

## 0.4.1

* Update Alloy to 1.5.3 (@petewall)

## 0.4.0

* Remove some of the special pod security contexts, because their values may cause issues on certain platforms (@petewall)
* Update Alloy to 1.5.2 (@petewall)

## 0.3.15

* Update Alloy to 1.5.1 (@petewall)

## 0.3.14

* Update Alloy to 1.5.0 (@petewall)
* Update Operator Framework to 1.42.0 (@petewall)
* Add the ability to make pod and container security contexts optional, or override the fs, group, and user IDs (@petewall)

## 0.3.12

* Update Alloy to 1.4.0 (@petewall)

## 0.3.11

* Update Alloy to 1.3.1 (@petewall)

## 0.3.10

* Update Alloy to 1.3.0 (@petewall)
* Fix conditional syntax for API version checks (@siryur)
* Restrict pod and container security contexts (@petewall)
* Add the ability to deploy a ServiceMonitor for the Alloy Operator (@petewall)

## 0.3.9

* Add the ability to create and manage Roles and RoleBindings (@petewall)

## 0.3.8

* Update Alloy to 1.2.1 (@petewall)

## 0.3.7

* Add the ability to pass extra arguments to the Alloy Operator container (@petewall)

## 0.3.6

* Update Alloy to 1.2.0 (@petewall)

## 0.3.5

* Convert to the new test system (@petewall)
* Allow for setting image by digest (@petewall)

## 0.3.4

* Update Alloy to 1.1.2 (@petewall)

## 0.3.3

* Ensure that the Deployment and Service objects are properly namespaced (@petewall)
* Remove extra files from the Helm chart that are not needed (@petewall)

## 0.3.2

* Add the ability to restrict the Alloy Operator to specific namespaces (@petewall)

## 0.3.1

* Update Alloy to 1.1.1 (@petewall)

## 0.3.0

* Removing default resource requests and limits (@petewall, @kespineira)
* Adding values.schema.json to validate the inputs (@petewall)
* Add GitHub Action linting (@petewall)
* Add the ability to enable or disable RBAC object creation (@petewall)

## 0.2.10

* Update Alloy to 1.1.0 (@petewall)

## 0.2.9

* Added more integration tests (@petewall)
* Added RBAC rules for HPA (@petewall)
* Added RBAC rules for Ingress, Prometheus Rules, and Prom operator objects (@discostur)
* Added RBAC rules for PDB (@tw-sematell)

## 0.2.8

* Set node selector by default (@petewall)
* Update the build flag so it updates based on alloy version (@petewall)
* Fix YAML linting (@petewall)
* Set Apache 2.0 license (@tomwilkie)

## 0.2.7

* Update Alloy to 1.0.3 (@petewall)
* Include the CRD in the GitHub release (@petewall)

## 0.2.2

* Added the ability to override image registry and pull secrets with the global option (@petewall)
* Added alloy-values.yaml, the default values, to the Helm chart as a base file (@petewall)

## 0.2.1

* Updated README (@petewall)

## 0.2.0

* First Helm release (@petewall)

## 0.1.0

* Initial prototype (@petewall)
