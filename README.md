# must-gather-script

I have designed this script to enhance the collection of must-gather data.

### Prerrequisites:
> - You must have your RHN username and password provided by Red Hat, i.e.: `rhn-support-xxx`

If you need to check the upload container you could run the following command:

~~~
POD_NAME=$(oc get pods -n openshift-must-gather-operator |grep -i mustgather |awk '{print $1}')

oc logs $POD_NAME -n openshift-must-gather-operator -c upload
~~~


