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
            #print(errorIndication)

        elif errorStatus:
            print('%s at %s' % (errorStatus.prettyPrint(),
                                errorIndex and varBinds[int(errorIndex) - 1][0] or '?'))

        else:
            for varBind in varBinds:
                print(' = '.join([x.prettyPrint() for x in varBind]))
            #exit()
import time

if __name__ == "__main__":
    Router.snmp('noruega','192.168.2.10')
    time.sleep(10)
    cisco = Router("cisco_ios", "192.168.2.10", "daniel", "daniel", 22)
    mikrotik = Router("mikrotik_routeros", "192.168.2.11", "daniel", "daniel", 22)
    cisco.conexion()
    #mikrotik.conexion()
    cisco.comando('show running-config')

"""

pregunta = input("Dime la ip a analizar: ")
with open('ips.txt') as wordlist:
    for line in wordlist:
            if pregunta == line.strip():
                print("Obteniendo informacion de la IP: ",line.strip()) # Recoger IPS.
                with open('comunidades.txt') as comunidades:
                    for comunidad in comunidades:
                        print("Probando Comunidad: %s" % comunidad)
                        
                        iterator = getCmd(
                            SnmpEngine(),
                            CommunityData(comunidad.strip(), mpModel=0), # Mi Comunidad es daniel
                            UdpTransportTarget((line.strip(), 161)), # HOST, PUERTO APLICO UN STRIP PARA QUITAR LOS ESPACIOS ENTRE LAS IPS
                            ContextData(),
                            ObjectType(ObjectIdentity(cpu_oid)) # PONER EL OID DEL ROUTER
                        )

                        errorIndication, errorStatus, errorIndex, varBinds = next(iterator)

                        if errorIndication:
                             if "No SNMP response received before timeout" in str(errorIndication):
                                  print("[-] Pasando a la siguiente comunidad.")
                            #print(errorIndication)

                        elif errorStatus:
                            print('%s at %s' % (errorStatus.prettyPrint(),
                                                errorIndex and varBinds[int(errorIndex) - 1][0] or '?'))

                        else:
                            for varBind in varBinds:
                                print(' = '.join([x.prettyPrint() for x in varBind]))
                            exit()

"""
