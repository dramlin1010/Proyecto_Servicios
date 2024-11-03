from python_terraform import Terraform
import requests

my_ip = requests.get("http://api.myip.com").json()['ip'] + "/32"

def creacion_de_vpc():
    tf = Terraform(working_dir="terraform/")
    tf.init(capture_output=False)
    tf.apply(var={"ip": my_ip}, capture_output=False, skip_plan=True)

if __name__ == "__main__":
    creacion_de_vpc()
