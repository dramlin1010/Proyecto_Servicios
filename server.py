# TFPT
import tftpy
import threading
from python_terraform import Terraform # Uso de python_terraform -> https://www.linkedin.com/pulse/infrastructure-code-python-terraform-mihai-vlad-stoica
import configparser # USAR FICHERO DE CONFIGS
import os

config = configparser.ConfigParser()
config.read('aws.conf')

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

    def iniciar_server(self):
         thread = threading.Thread(target=self.escuchar())
         thread.daemon = True
         thread.start()    

# APLICAR MEJORA DE PODER CREAR VARIOS BUCKETS A LA VEZ, PARA ELLO HAY QUE VERIFICAR SI EL ARCHIVO EXISTE. EN ESE CASO NO INTRODUCIR PROVIDER
# Y TENER QUE ENUMERAR CADA nombre de bucket resource.

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
        
        with open(os.path.join(directorio_terraform, 'bucket.tf'), 'w') as f: # PARA NUEVA ACTUALIZACION PARA IMPLEMENTAR VARIOS BUCKETS DEBEREMOS DE CAMBIARLO a 'a' APPEND.
            f.write(tf_config)

        tf = Terraform(working_dir=directorio_terraform)
        tf.init(capture_output=False)
        tf.apply(skip_plan=True, capture_output=False)

        # resultado = (0, None, None) -> Cuando no hay cambios


if __name__ == "__main__":

    pregunta = input("Quieres crear un bucket? [S o N]: ")

    if pregunta == "Y" or pregunta == "S" or pregunta == "Si" or pregunta == "si":
        nombre_bucket = input("[Opcional] Como quieres que se llame el bucket (Ejemplo -> s3-bucket-NOMBRE-test): ")
        crear_bucket(nombre_bucket)
        print("\n[+] Inicializando el servidor TFTP\n")
    elif pregunta == "":
        exit(0)
    mitfpt = Tftp('0.0.0.0',69,'archivos')
    mitfpt.asignar_directorio()
    mitfpt.iniciar_server()