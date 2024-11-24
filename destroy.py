from python_terraform import Terraform
import requests
import subprocess

my_ip = requests.get("http://api.myip.com").json()['ip'] + "/32"

def destroy_indra():
    terraform_dir = "terraform/"

    command = [
        "terraform", "destroy",
        "-auto-approve",
        f"-var=ip={my_ip}"
    ]

    try:
        # Ejecutar el comando en el directorio especificado
        result = subprocess.run(command, cwd=terraform_dir, text=True, capture_output=True, check=True)
        print("Destroy completado con éxito.")
        print(result.stdout)
    except:
        print("Error durante el destroy:")

if __name__ == "__main__":
    destroy_indra()
