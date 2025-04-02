kapp deploy -a ootb-templates-app -n tap-install -f <(ytt -f ./ootb-templates/ --data-values-file ootb-templates-data-values.yaml)

ootb_templates:
  excluded_templates:
  - carvel-package
  - config-writer-template # Needs to become a ClusterConfigTemplate
  - kaniko-template
  - package-config-writer-and-pull-requester-template
  - package-config-writer-template 
  - config-writer-and-pull-requester-template 

