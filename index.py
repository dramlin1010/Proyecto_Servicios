#from pysnmp.hlapi import *
from pysnmp.hlapi import getCmd, SnmpEngine, CommunityData, UdpTransportTarget, ContextData, ObjectType, ObjectIdentity

cpu_oid = '1.3.6.1.4.1.9.2.1.58.0'

iterator = getCmd(
    SnmpEngine(),
    CommunityData('daniel', mpModel=0), # Mi Comunidad es daniel
    UdpTransportTarget(('192.168.2.10', 161)), # HOST, PUERTO
    ContextData(),
    ObjectType(ObjectIdentity(cpu_oid)) # PONER EL OID DEL ROUTER
)

errorIndication, errorStatus, errorIndex, varBinds = next(iterator)

if errorIndication:
    print(errorIndication)

elif errorStatus:
    print('%s at %s' % (errorStatus.prettyPrint(),
                        errorIndex and varBinds[int(errorIndex) - 1][0] or '?'))

else:
    for varBind in varBinds:
        print(' = '.join([x.prettyPrint() for x in varBind]))
