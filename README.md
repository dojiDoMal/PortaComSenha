# PortaComSenha
Código para simulação de um porta com senha utilizando Assembly 8051

> Entre com a senha para destrancar a porta, o LCD mostratrá mensagem de erro ou acerto. Após três tentativas erradas você terá que esperar 30 segundos para tentar novamente.

## 🚀 Executando o projeto 

Para executar o código basta abrir a IDE localizada em `edsim51di/edsim51di.jar` (Necessário ter java instalado) e utilizar o código disponibilizado em `source/senha8051.asm`.

A IDE já contém as configurações necessárias para executar o código.

## 💻 Lista de uso

São utilizados os seguintes componentes do micro 8051:

- Interrupção externa 0 
- Timer 0
- Registradores R1 ao R7
- ACC, B, C
- P1.0 ao 1.7, P2, P3.2

## 📝 Licença

Esse projeto está sob licença. Veja o arquivo [LICENÇA](LICENSE.md) para mais detalhes.
