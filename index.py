from pysnmp.hlapi import getCmd, SnmpEngine, CommunityData, UdpTransportTarget, ContextData, ObjectType, ObjectIdentity
from netmiko import ConnectHandler

cpu_oid = '1.3.6.1.4.1.9.2.1.58.0'

class Router:
    def __init__(self, device_type, host, username, password, port):
        self.device_type = device_type
        self.host = host
        self.username = username
        self.password = password
        self.port = port

    def conexion(self):
        router = {
            'device_type': self.device_type,
            'host': self.host,
            'username': self.username,
            'password': self.password,
            'port': self.port
        }
        self.net_connect = ConnectHandler(**router)
        print(f"Conexión completada a {self.host}.")

    def comando(self, comd):
        output = self.net_connect.send_command(comd)
        print(output)

def snmp(comunidad, ip):
    iterator = getCmd(
        SnmpEngine(),
        CommunityData(comunidad, mpModel=0),
        UdpTransportTarget((ip, 161)),
        ContextData(),
        ObjectType(ObjectIdentity(cpu_oid)) # OID
    )
    errorIndication, errorStatus, errorIndex, varBinds = next(iterator)

    if errorIndication:
            if "No SNMP response received before timeout" in str(errorIndication):
                print("[-] Pasando a la siguiente comunidad.")

    elif errorStatus:
        print('%s at %s' % (errorStatus.prettyPrint(),
                            errorIndex and varBinds[int(errorIndex) - 1][0] or '?'))

    else:
        for varBind in varBinds:
            print(' = '.join([x.prettyPrint() for x in varBind]))

if __name__ == "__main__":
    with open("ips.txt", "r") as ips, open("comunidades.txt", "r") as comunidades: # Leyendo ficheros
        ips = ips.read().splitlines()  # Lista de IPs
        comunidades = comunidades.read().splitlines()  # Lista de comunidades

    choice = input("Quieres ejecutar un comando o consultar una IP por SNMP? (comando/snmp): ").strip()

    if choice == "comando":
        router_type = input("Selecciona el tipo de router (cisco, mikrotik, bird, juniper): ").strip()

        if router_type == "cisco":
            device_type = "cisco_ios"
        elif router_type == "mikrotik":
            device_type = "mikrotik_routeros"
        elif router_type == "bird":
            device_type = "linux"
        elif router_type == "juniper":
            device_type = "juniper"
        else:
            print("Tipo de router no valido.")
            exit(1)

        command = input("Introduce el comando que deseas ejecutar: ").strip()

        for ip, comunidad in zip(ips, comunidades):
            print(f"\nConectando al router con IP {ip} y comunidad {comunidad}...")
            router = Router(device_type, ip, "daniel", "daniel", 22) # Poniendo las creds por defecto.
            router.conexion()
            router.comando(command)

    elif choice == "snmp":
        for ip, comunidad in zip(ips, comunidades):
            print(f"\nConsultando SNMP para IP {ip} y comunidad {comunidad}...")
            snmp(comunidad, ip)

    else:
        print("No valido. Por favor, elige 'comando' o 'snmp'.")
