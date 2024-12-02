import subprocess

def destroy_indra():
    terraform_dir = "terraform/"
    public_key_value = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCtSeswCwk/f23nuiR4ShNZbRVDLgXxYUUpSEHqB1x7rOX1ahNcCpYlmy9/fzOT/kOTaST9ajA/zuQr4NKo84d4RfkgRKt5vUI0N2a32n9FEpMllbLVXPUAvNZ03RMYIUZygbwgqULf3Zl+Z3qC0s58DrrcT2BeGO8FHw+oonSBcMz2X7pSd57AxuvcZiL7R85BdIMk2kXer69fdu+L3OlYF6ebnF4lFvaRF+veSzgiTvQZ+TqjbGeG4rTvZv7gl+RQNEOurIR9+MvdpYSCamRuBCg3q3LaanfycT+1Q6vPlYvSxDbdLWhclWYZeq2r1IUCKuEHb6s5527zHpfdKZfbn0i0yqJhyQ+NdLMqBJ3pKLJHGJteW2VIUvXN24t1wddnoHrqsOZ7MmBcXYa5s657xZLIgQB5WoaGd1vVyNT7zwaqBm5foGnxa43nNVVIFAByvGJ1jOMJnyxC8AMkHkW1hY8PYvhn/h2tAsRSI23yAuaSxsGEx7O2M1RgRTV04dB2LGsopjQiKGpqb6Kay6aP2q6tdaUUpnCk575uG/2A5o5rgzYIPWkSzN46Ar6cpkF/Bz+iVK8yfuco06HvOVv7+KrPG04voPzRkPrQxv4NEyc09OP7nSDxkjCpmVSmevACXUbsWep77O2EUUR0nQktsEDPcPTzMBoshRz4rF3EMQ== 2asir@ciclo.com"

    command = [
        "terraform", "destroy",
        "-auto-approve",
        f"-var=public_key={public_key_value}"
    ]

    try:
        # Ejecutar el comando en el directorio especificado
        result = subprocess.run(command, cwd=terraform_dir, text=True, capture_output=True, check=True)
        print("Destroy completado con éxito.")
        print(result.stdout)
    except subprocess.CalledProcessError as e:
        print("Error durante el destroy:")
        print(e.stderr)

if __name__ == "__main__":
    destroy_indra()
