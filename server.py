# TFPT
import tftpy
import threading
from python_terraform import Terraform # Uso de python_terraform -> https://www.linkedin.com/pulse/infrastructure-code-python-terraform-mihai-vlad-stoica
import configparser # USAR FICHERO DE CONFIGS
import os

config = configparser.ConfigParser()
config.read('aws.conf')

aws_access_key = config.get('config', 'access_key')
aws_secret_key = config.get('config', 'aws_secret_access_key')
aws_region = config.get('config', 'aws_region')
class Tftp():
    def __init__(self, ip, puerto, directorio):
        self.ip = ip
        self.puerto = puerto
        self.directorio = directorio
    
    def asignar_directorio(self):
        self.server = tftpy.TftpServer(self.directorio)
    
    def escuchar(self):
        self.server.listen(self.ip, self.puerto)
"""
def check_bucket(bucket_name):
    tf = Terraform(working_dir='terraform/')
    direccion = "aws_s3_bucket.bucket_ejemplo"
    args = ['import', direccion, bucket_name]

    respuesta = tf.cmd(*args)

    if respuesta == 0:
        print(f"[+] El bucket {bucket_name} ya existe.")
    else:
        print(f"[-] El bucket {bucket_name} no existe, creandolo.....")
        crear_bucket(bucket_name)
"""

def crear_bucket(bucket_name):
        tf_config = f"""
provider "aws" {{
        region     = "{aws_region}"
        }}
resource "aws_s3_bucket" "bucket_ejemplo" {{
    bucket = "{bucket_name}"
    tags = {{
        Name = "Bucket de Prueba Automatizado."
    }}
    }}
        """
        directorio_terraform = 'terraform/'
        
        with open(os.path.join(directorio_terraform, 'initial.tf'), 'w') as f:
            f.write(tf_config)

        tf = Terraform(working_dir=directorio_terraform)
        tf.init(capture_output=False)
        tf.apply(skip_plan=True, capture_output=False)

if __name__ == "__main__":
    #check_bucket("s3-bucket-daniel-test")
    crear_bucket("s3-bucket-daniel-test")
    exit(0) # DE PRUEBAS DE MOMENTO
    mitfpt = Tftp('0.0.0.0',69,'archivos')
    mitfpt.asignar_directorio()
    mitfpt.escuchar()