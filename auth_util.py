
import yaml, subprocess, json, re, sys

FILE_NAME = 'auth_config.yaml'
KUBERNETES_GROUP = 'system:masters'

cmd = f'kubectl get configmap aws-auth -n kube-system -o yaml > {FILE_NAME}'

MASTER_PARSER = '({["rolearn":"arn]+[:a-z0-9\/\w-]+"[,"\w\/-:{{{]*[-\w}}",:\[]*[\]]*})' #regex101

def execute_cmd(cmd):
    subprocess.Popen(cmd,stdout=subprocess.PIPE,shell=True).communicate()
    
def add_role(role_name,account_number='698347480743'):
   return  str({"rolearn": f"arn:aws:iam::{account_number}:role/{role_name}", "username": f"{role_name}", "groups": [KUBERNETES_GROUP]})

def parse_auth_data(data):
    return re.findall(MASTER_PARSER,data)

def run(role_name,account_number='698347480743'):
    execute_cmd(cmd)
    with open(FILE_NAME, 'r') as ink:
        pre_formatted = ink.read()
        content = yaml.safe_load(pre_formatted)
        result = content.get('data').get('mapRoles')
        roleArns = parse_auth_data(result)
        value = add_role(role_name,account_number)
        parsed_dictionary_string = str(json.loads(value.replace("'",r'"')))
        roleArns.append(parsed_dictionary_string.replace("'",r'"'))
        newRoleArnListString = "[" + ','.join(roleArns) + "]"
        content['data']['mapRoles'] = newRoleArnListString
        with open(FILE_NAME, 'w') as inkwell:

            yaml.dump(content, inkwell)
        

if __name__ == "__main__":

    try:
        roleName = sys.argv[1] 
        userName = sys.argv[2]
        run(roleName,userName)
    except Exception as e:
        print(str(e))

# python3 auth_util.py  arn:aws:iam::698347480743:role/eks-admin arn:aws:iam::698347480743:user/andyDufresne
# kubectl apply -f auth_config.yaml       
#Elliott Arnold generate aws auth configmap manifest that grants IAM users AWS Roles access to Kubernetes Cluster 
#MyFirstKubernetesScript Thank you Jesus
#6-17-22

# # python3 authconfig.py arn:aws:iam::698347480743:role/eks-admin arn:aws:iam::359868554540:user/svc_devops
# python3 auth_util.py  newRole newUserName

# arn:aws:iam::698347480743:user/el_kratos