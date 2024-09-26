#from pysnmp.hlapi import *
from pysnmp.hlapi import getCmd, SnmpEngine, CommunityData, UdpTransportTarget, ContextData, ObjectType, ObjectIdentity

cpu_oid = '1.3.6.1.4.1.9.2.1.58.0'

#comunidad = "daniel"

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