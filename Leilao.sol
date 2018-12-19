pragma solidity ^0.5.1;

contract Leilao { 
    //Estrutura de um Participante
    struct Participante{
        address endereco;
        uint desconto;
        uint parcelas;
        uint indice;
        bool ganhando;
    }
    
    //Estrutura de um Ganhador
    struct Ganhador{
        address endereco;
        uint posicaoParticipantes;
    }
    
    //atributos da divida 
    uint valorTotal;
    uint parcelasDivida;
    uint tipo;
    uint diasAtraso;
    uint formaPagamento;
    string localizacao;
    uint tipoDevedor;
    
    //Regras do lance
    uint maxFormaPagamento = 2;
    uint maxTipo = 2;
    uint maxTipoDevedor = 1;
    uint percentDesconto;
    uint quantidadeParcelas;
    uint percentDescontoMax;
    uint quantidadeParcelasMax;
    uint pesoDesconto;
    uint pesoParcela;
    uint indiceEsperado;
    // tipo 1: aberto, tipo 2: privado
    uint tipoLeilao;
    
    //informações do leilão
    uint private id; //IDENTIFICADOR DO LEILÃO 
    Ganhador private usuarioGanhando;
    address private dono; //QUEM CRIOU O LEILÃO
    uint estado;
    string objetoLeiloado;
    uint tempoCriacao;
    uint modoFinalizacao;
    uint tempoAtivo; //EM MILISSEGUNDOS
    uint _tempoIniciar;
    uint _tempoPendente;
    bool cobrado = false;
    bool cancelado = false;
    bool finalizado;
    uint tempoInicioPendente;
    
    //MODOS DE FINALIZACAO
    struct OpcaoFinalizar{
        uint id;
        string descricao;
    }
    OpcaoFinalizar[] opcoesFinalizacao;
    
    //SOBRE OS PARTICIPANTES DO LEILAO
    address[] participantes;
    address[] usuariosPermitidos;
    address[] usuariosNaoPermitidos;
    uint[] idsParticipantes;
    mapping(address => uint) private positionParticipante;
    mapping(uint => Participante) private infoParticipante; 
    
    //EVENTOS
    event Lance(address enderecoPessoa, uint desc,uint parce, uint ind, string resultado);
    event Resultado(address enderecoDono, address enderecoVencedor, uint quantia);
    
    /**
        @notice Construtor do contrato Leilao, instancia os atributos do leilao e da divida
        @param  _enderecoDono endereço de quem é o dono do Leilão
        @param  _id identificador do leilao
        @param  _modoFinalizacao modo de finalizacao do leilao 
        @param hashObjeto endereço do documento no IPFS
        @param infoLeilao array contendo as informações do leilao em cada posicao, posicoes: [0] tempo do leilao,
        [1] porcentagem de desconto, [2] quantidade de parcelas, [3] numero maximo de Parcelas permitido no lance, 
        [4] porcentagem maxima de Desconto permitida no lance, [5] peso de importancia do Desconto para o lance
        (usado para calculo do indice), [6] peso de importancia da Parcela 
        para o lance (usado para calculo do indice)
        @param usersParticipantes lista de endereços dos usuários que podem participar do Leilão, sendo que se estiver vazia
        o leilão é aberto
        @param usersNaoParticipantes lista de endereços dos usuários que não podem participar do Leilão
    */
    constructor(uint _id, address _enderecoDono, uint _modoFinalizacao,  string memory hashObjeto,uint[] memory infoLeilao, address[] memory usersParticipantes, address[] memory usersNaoParticipantes)public{
        opcoesFinalizacao.push(OpcaoFinalizar(0,"Cronometro"));
        opcoesFinalizacao.push(OpcaoFinalizar(1,"ValorAtingir"));
        opcoesFinalizacao.push(OpcaoFinalizar(2,"DonoFinaliza"));
        uint _tempo ;
        uint pDesconto ;
        uint numParcelas;
        uint numParcelasMax;
        uint pDescontoMax;
        uint pesDesconto ;
        uint pesParcela;
        uint tempoIniciar;
        uint tempoPendente;
        
        if(infoLeilao.length > 0){
            _tempo = infoLeilao[0];
        if(infoLeilao[1] >= 0 ){
            pDesconto = infoLeilao[1];
        }else{
            pDesconto = 0;
        }
        if(infoLeilao[2] >= 0){
            numParcelas = infoLeilao[2];
        }else{
            numParcelas = 0;
        }
        if(infoLeilao[3] >= 0){
            numParcelasMax = infoLeilao[3];
        }else{
            numParcelasMax = 0;
        }
        if(infoLeilao[4] >= 0){
            pDescontoMax = infoLeilao[4];
        }else{
            pDescontoMax = 0;
        }
        if(infoLeilao[5] >= 0){
            pesDesconto = infoLeilao[5];
        }else{
            pesDesconto = 0;
        }
        if(infoLeilao[6] >= 0){
            pesParcela = infoLeilao[6];
        }else{
            pesParcela = 0;
        }
            tempoIniciar = infoLeilao[7];    
            tempoPendente = infoLeilao[8];

        }
        
        require(pDesconto >= 0);
        require(numParcelas >= 0);
        require(pesDesconto >= 0);
        require(pesParcela >= 0);
        require(2 >= _modoFinalizacao && _modoFinalizacao >= 0);
        if(opcoesFinalizacao[1].id == _modoFinalizacao ){
         require(numParcelas <= numParcelasMax);
         require(pDesconto <= pDescontoMax);   
        }
        require(_tempo >= 0);
        require(tempoIniciar >= 0);
        require(tempoPendente >= 0);
        modoFinalizacao = _modoFinalizacao;
       
       usuariosPermitidos = usersParticipantes;
       usuariosNaoPermitidos = usersNaoParticipantes;
       if(usuariosPermitidos.length > 0){
           tipoLeilao = 2;
       }else{
           tipoLeilao = 1;
       }
        _tempoIniciar = tempoIniciar;
        _tempoPendente = tempoPendente;
        tempoAtivo = _tempo;
        id = _id;
        dono = _enderecoDono;
        objetoLeiloado = hashObjeto;
        estado = 0;
        tempoCriacao = now;
        tempoInicioPendente = tempoCriacao + _tempoIniciar + tempoAtivo;
        if(pDesconto == 0){
         percentDesconto = 1;   
         percentDescontoMax = 1; 
            pesoDesconto = 0;
        }else{
            percentDesconto = pDesconto;
            percentDescontoMax = pDescontoMax;
            pesoDesconto = 1;
        }
        
        if(numParcelas == 0){
            quantidadeParcelas = 1;   
            quantidadeParcelasMax = 1; 
            pesoParcela = 0;
        }else{
            quantidadeParcelas = numParcelas;
            quantidadeParcelasMax = numParcelasMax;
            pesoParcela = 1;
        }
       
        if(opcoesFinalizacao[0].id == modoFinalizacao || opcoesFinalizacao[1].id == modoFinalizacao){
            pesoDesconto = pesDesconto;
            pesoParcela = pesParcela;
        }
        indiceEsperado = calculaIndice(percentDesconto, quantidadeParcelas); 
    }
    
    /**
        @notice Função utilizada para atributos as informações da divida visiveis aos usuários ao leilao
        @param  _localizacao cidade e estado da divida 
        @param  atributos array contendo as informações da divida que vai ser leiloada, posicoes: [0] valor total da divida,
        [1] quantidade de parcelas da divida, [2] tipo da divida, [3] dias de atraso até o momento, [4] forma de pagamento,
        [5] tipo de devedor
    */
    function setAtributos(uint[] memory atributos,string memory _localizacao) public{
        require(atributos.length == 6);
        require(atributos[0] > 0);
        require(atributos[1] >= 0);
        require(atributos[2] >= 0 && atributos[2] <= maxTipo);
        require(atributos[3] > 0);
        require(atributos[4] >= 0 && atributos[4] <= maxFormaPagamento);
        require(atributos[5] >= 0 && atributos[5] <= maxTipoDevedor);
        
        valorTotal = atributos[0];
        parcelasDivida = atributos[1];
        tipo = atributos[2];
        diasAtraso = atributos[3];
        formaPagamento = atributos[4];
        localizacao = _localizacao;
        tipoDevedor = atributos[5];
    }
    
    modifier apenasDono(address pessoa){
        require(pessoa == dono);
        _; 
    }
     
    modifier quandoNaoFinalizado(address enderecoPessoa){
        require(!leilaoFinalizado());
        _;
    }
    
/**
        @notice Função utilizada para calcular um indice com base nos paramtros para lance de um leilao, o indice sera utilizado para saber qual o lance é o melhor
        @param  lanceDesconto porcentagem de desconto que foi dado no lance
        @param  lanceParcelas quantidade de parcelas dadas no lance
        @return indice gerado de um calculo em cima da porcentagem de desconto e da quantidade de parcela
    */
    function calculaIndice( uint lanceDesconto,uint lanceParcelas)public view returns(uint indice) {
        
        uint xDesconto = ((lanceDesconto *100) / percentDesconto) * (pesoDesconto*10);
        uint xParcelas = ((lanceParcelas *100)/ quantidadeParcelas) * (pesoParcela*10);
        
        indice = xDesconto + xParcelas;
    }
    
    /**
        @notice Função utilizada para adicionar um novo lance e verificar em que tipo de leilao ira ser dado o lance
        @param  enderecoPessoa endereço de quem esta solicitando a função para saber se é o dono do Leilão
        @param  desconto porcentagem de desconto que foi dado no lance
        @param  parcelas quantidade de parcelas dadas no lance
        @dev Verifica qual o modo de finalizacao do leilao chamando funcoes especificas para cada modo
    */
     function addLance(address enderecoPessoa, uint desconto,uint parcelas)public {
        require(!(leilaoFinalizado()));
        require(dono != enderecoPessoa);
        require(desconto >= 0 );
        require(parcelas >= 0 );
        require(verificaEstado() == 1);
        require(tipoLeilao == 2? isPermitido(enderecoPessoa) : !semPermissao(enderecoPessoa));
        
        uint indice = calculaIndice(desconto,parcelas);
        
        if(opcoesFinalizacao[0].id == modoFinalizacao){
            
            if(indice> indiceEsperado){
                emit Lance(enderecoPessoa,desconto,parcelas,indice,"Lance não esta ganhando");
            }else{
                addLanceCronometro(enderecoPessoa,indice,desconto,parcelas);
            }
        }else if(opcoesFinalizacao[1].id == modoFinalizacao){
            addLanceValor(enderecoPessoa,indice,desconto,parcelas);
        
        }else{
            addLanceManual(enderecoPessoa,indice,desconto,parcelas);
        }
    }
    
    /**
        @notice Função utilizada para adicionar um novo lance no modo de finalizacao manual
        @param  enderecoPessoa endereço de quem esta solicitando a função para saber se é o dono do Leilão
        @param  desconto porcentagem de desconto que foi dado no lance
        @param  parcelas quantidade de parcelas dadas no lance
        @param valor indice gerado de um calculo em cima da porcentagem de desconto e da quantidade de parcela
    */
    function addLanceManual(address enderecoPessoa, uint valor, uint desconto, uint parcelas) public payable{
        require(!(leilaoFinalizado()));
        require(valor > 0);
        require(desconto <= percentDesconto, "Valores abaixo do esperado");
        require( parcelas <= quantidadeParcelas,"Valores abaixo do esperado");
        require(
            infoParticipante[usuarioGanhando.posicaoParticipantes].indice != 0 
            ? infoParticipante[usuarioGanhando.posicaoParticipantes].indice > valor : true
        );
        Participante memory p = Participante(enderecoPessoa, desconto,parcelas,valor, true);
    
        //SE FOR O PRIMEIRO A DAR LANCE
        if(participantes.length > 0){
            infoParticipante[usuarioGanhando.posicaoParticipantes].ganhando = false;
        }
    
        uint pos = participantes.push(enderecoPessoa);
        idsParticipantes.push(pos);
        positionParticipante[enderecoPessoa] = pos;
        infoParticipante[pos] = p;
        usuarioGanhando = Ganhador(enderecoPessoa, pos);
    
        emit Lance(enderecoPessoa,  desconto, parcelas,valor,"Sucesso");
    }
     /**
        @notice Função utilizada para adicionar um novo lance no modo de finalizacao por Valor ou Tempo
        @param  enderecoPessoa endereço de quem esta solicitando a função para saber se é o dono do Leilão
        @param  desconto porcentagem de desconto que foi dado no lance
        @param  parcelas quantidade de parcelas dadas no lance
        @param valor indice gerado de um calculo em cima da porcentagem de desconto e da quantidade de parcela
    */
     function addLanceValor(address enderecoPessoa, uint valor, uint desconto, uint parcelas) public payable{
        require(!(leilaoFinalizado()));
        require(valor > 0);
        require(desconto <= percentDescontoMax, "Valores abaixo do esperado");
        require( parcelas <= quantidadeParcelasMax,"Valores abaixo do esperado");
        require(
            infoParticipante[usuarioGanhando.posicaoParticipantes].indice != 0 
            ? infoParticipante[usuarioGanhando.posicaoParticipantes].indice > valor : true
        );
        Participante memory p = Participante(enderecoPessoa, desconto,parcelas,valor, true);
    
        //SE FOR O PRIMEIRO A DAR LANCE
        if(participantes.length > 0){
            infoParticipante[usuarioGanhando.posicaoParticipantes].ganhando = false;
        }
    
        uint pos = participantes.push(enderecoPessoa);
        idsParticipantes.push(pos);
        positionParticipante[enderecoPessoa] = pos;
        infoParticipante[pos] = p;
        usuarioGanhando = Ganhador(enderecoPessoa, pos);
        
        if(valor <=  indiceEsperado){
            finalizado = true;
            tempoInicioPendente = now;
        }
        emit Lance(enderecoPessoa,  desconto, parcelas,valor,"Sucesso");
    }
    /**
        @notice Função utilizada para adicionar um novo lance no modo de finalizacao por Tempo
        @param  enderecoPessoa endereço de quem esta solicitando a função para saber se é o dono do Leilão
        @param  desconto porcentagem de desconto que foi dado no lance
        @param  parcelas quantidade de parcelas dadas no lance
        @param valor indice gerado de um calculo em cima da porcentagem de desconto e da quantidade de parcela
    */
    function addLanceCronometro(address enderecoPessoa, uint valor, uint desconto, uint parcelas) public payable{
        require(!(leilaoFinalizado()));
        require(valor > 0);
        require(desconto <= percentDesconto, "Valores abaixo do esperado");
        require( parcelas <= quantidadeParcelas,"Valores abaixo do esperado");
        require(
            infoParticipante[usuarioGanhando.posicaoParticipantes].indice != 0 
            ? infoParticipante[usuarioGanhando.posicaoParticipantes].indice > valor : true
        );
        
        Participante memory p = Participante(enderecoPessoa, desconto,parcelas,valor, true);
    
        //SE FOR O PRIMEIRO A DAR LANCE
        if(participantes.length > 0){
            infoParticipante[usuarioGanhando.posicaoParticipantes].ganhando = false;
        }
    
        uint pos = participantes.push(enderecoPessoa);
        idsParticipantes.push(pos);
        positionParticipante[enderecoPessoa] = pos;
        infoParticipante[pos] = p;
        usuarioGanhando = Ganhador(enderecoPessoa, pos);
       
         emit Lance(enderecoPessoa,  desconto, parcelas,valor,"Sucesso");
    }
    
    /**
        @notice Função utilizada para botar o usuário na lista dos perimitidos no leilão
        @param  user endereço do usuário que vai ser colocado na lista dos perimitidos no leilão
        @return exceção caso que esteja solicitando não seja dono do leilão
    */
    function setPermitido(address user) public{
        require(msg.sender == dono);
        
        usuariosPermitidos.push(user);
    }
    
    /**
        @notice Função utilizada para botar o usuário na lista dos não perimitidos no leilão
        @param  user endereço do usuário que vai ser colocado na lista dos não perimitidos no leilão
        @return exceção caso que esteja solicitando não seja dono do leilão
    */
    function setSemPermissao(address user) public{
        require(msg.sender == dono);
        
        usuariosNaoPermitidos.push(user);
    }
    
     /**
        @notice Função utilizada para verificar se o usuário esta na lista dos perimitidos no leilão
        @param  user endereço do usuário para verificação se esta na lista dos perimitidos no leilão
    */
    function isPermitido(address user) public view returns(bool){
        for(uint i = 0; i < usuariosPermitidos.length; i++){
            if(usuariosPermitidos[i] == user){
                return true;
            }
        }
        return false;
    }
    
     /**
        @notice Função utilizada para verificar se o usuário esta na lista dos não perimitidos no leilão
        @param  user endereço do usuário para verificação se esta na lista dos não perimitidos no leilão
    */
    function semPermissao(address user) public view returns(bool){
        for(uint i = 0; i < usuariosNaoPermitidos.length; i++){
            if(usuariosNaoPermitidos[i] == user){
                return true;
            }
        }
        return false;
    }
    
    function getPermitidos()public view returns(address[] memory){
        return usuariosPermitidos;
    }
    
    function getNaoPermitidos()public view returns(address[] memory){
        return usuariosNaoPermitidos;
    }
    
    /**
        @notice Função utilizada para tornar o Leilão em estado de Pendente, ou seja, esperando a cobrança da divida
        @param  enderecoPessoa endereço de quem esta solicitando a função para saber se é o dono do Leilão
        @return Emite um evento de resultado
    */
    function tornaPendente(address enderecoPessoa) public{
        require(enderecoPessoa == dono);
        require(infoParticipante[usuarioGanhando.posicaoParticipantes].indice != 0);
        require(opcoesFinalizacao[2].id == modoFinalizacao);
        finalizado = true;
        estado =2;
        tempoInicioPendente = now;
        diasAtraso = getDiasDeAtrasoDaDivida();
        emit Resultado(dono, usuarioGanhando.endereco, infoParticipante[usuarioGanhando.posicaoParticipantes].indice);
    }
    
     /**
        @notice Função utilizada para tornar o Leilão em estado de Finalizado, ou seja, a divida ja foi cobrada pela empresa ganhadora do leilão
        @param  enderecoPessoa endereço de quem esta solicitando a função para saber se é o dono do Leilão
    */
    function terminaLeilao(address enderecoPessoa) public{
        require(enderecoPessoa == dono);
        estado =4;
    }
    
     /**
        @notice Função utilizada para consultar o numero identificador do leilão
        @return id numero identificador do leilão
    */
    function getId() public view returns(uint){
        return id;
    }
    
    /**
        @notice Função utilizada para consultar os participantes do leilão
        @return array de endereços dos participantes do leilão
    */
    function getParticipantes() public view returns(address[] memory ){
        return participantes;
    }
    
    /**
        @notice Função utilizada para consultar os numeros identificadores dos participantes do leilão
        @return array de numeros identificadores dos participantes do leilão
    */
    function getIdParticipantes() public view returns(uint[] memory ){
        return idsParticipantes;
    }
    
     /**
        @notice Função utilizada para verificar se um usuário esta participando do leilão
        @param enderecoPessoa endereco do usuario para verificação se esta participando do leilão
        @return true caso o endereço esteja na lista de participantes ou false caso não esteja na lista de participantes
    */
    function isParticipante(address enderecoPessoa) public view returns(bool){
        
        if(positionParticipante[enderecoPessoa] == 0){
            return false;
        }
        return true;
    }
    
    /**
        @notice Função utilizada para consultar um determinado Participante do leilão pelo seu endereço
        @param enderecoPessoa endereço do usuario para consultar a o usuário na lista de participantes
        @return idPessoa numero identificador do Participante
        @return lance indice do lance dado por esse usuário 
        @return ganhando true se o usuário em questão esta ganhando o leilão ou false se esta perdendo o leilão
    */
    function getParticipante(address enderecoPessoa) public view returns(uint idPessoa, uint lance, bool ganhando){
        Participante memory p = infoParticipante[positionParticipante[enderecoPessoa]];
        
        idPessoa = positionParticipante[enderecoPessoa];
        lance = p.indice;
        ganhando = p.ganhando;
    }
    
      /**
        @notice Função utilizada para consultar um determinado Participante do leilão pelo seu numero identificador
        @param idParticipante numero identificador do participante para consultar na lista de participantes
        @return endereco do Participante
        @return lance indice do lance dado por esse usuário 
        @return ganhando true se o usuário em questão esta ganhando o leilão ou false se esta perdendo o leilão
    */
    function getParticipanteById(uint idParticipante) public view returns(address endereco, uint lance, bool ganhando){
        Participante memory p = infoParticipante[idParticipante];
        endereco = p.endereco;
        lance = p.indice; 
        ganhando = p.ganhando;
    }
    
    /**
        @notice Função utilizada para consultar o dono do leilão
        @return chave endereco do dono do leilão
        @return idLeilao numero identificador do leilão
    */
    function getDono() public view returns(uint idLeilao, address chave){
        idLeilao = id;
        chave = dono;
    }
    
    /**
        @notice Função utilizada para consultar as informações do leilão
        @return idLeilao numero identificador do leilão
        @return chaveDono endereco do dono do leilão
        @return chaveDono endereco do usuário que esta ganhando o leilão até o momento
        @return maiorLance o maior lance dado até o momento, consequentemente sendo o lance de quem esta ganhando
        @return listaParticipantes array contendo os participantes do leilão
        @return listaIdsParticipantes array contendo o numero identificador dos participantes do leilão
        @return objetoSendoLeiloado endereco no IPFS do documento sendo leiloada
        @return tipoFinalizacao modo de finalizacao do leilao
        @return percentualDesconto percentual de Desconto esperado no leilao
        @return quantidadeDeParcelas quantidade de Parcelas esperadas no leilao 
        @return estadoLeilao o estado atual do leilão
        @return terminado true se o leilão ja esta finalizado ou false caso esteja em outro estado
    */
    function getDados() 
        public 
        view 
        returns(
            uint idLeilao, 
            address chaveDono, 
            address chaveUsuarioGanhando, 
            uint maiorLance, 
            address[] memory listaParticipantes, 
            uint[] memory listaIdsParticipantes, 
            string memory objetoSendoLeiloado, 
            uint tipoFinalizacao, 
            uint percentualDesconto,
            uint quantidadeDeParcelas,
            uint estadoLeilao,
            bool terminado
        )
    {
            
        idLeilao = id;
        chaveDono = dono;
        chaveUsuarioGanhando = usuarioGanhando.endereco;
        maiorLance = infoParticipante[usuarioGanhando.posicaoParticipantes].indice;
        listaParticipantes = participantes;
        listaIdsParticipantes = idsParticipantes; 
        objetoSendoLeiloado = objetoLeiloado;
        terminado = leilaoFinalizado();
        percentualDesconto = percentDesconto;
        quantidadeDeParcelas = quantidadeParcelas;
        estadoLeilao = verificaEstado(); 
        tipoFinalizacao = modoFinalizacao;
        
    }
    
    /**
        @notice Função utilizada para consultar as informações da dívida
        @return valorTotalDivida valor total da dívida para cobrança
        @return parcelasDivi numero de parcelas da dívida 
        @return tipoDivida tipo de dívida do leilão (ex: cartão de crédito, seguro)
        @return diasdeAtraso dias de atraso da dívida até o momento
        @return formadePagamento de que forma foi realizado o pagamento da dívida (ex: cartão de crédito, boleto)
        @return _localizacao cidade e estado de onde a divida foi estabelecida
        @return tipodeDevedor qual o tipo de devedor (ex: pessoa física, jurídica)
    */
    function getAtributosDivida() public view returns 
        (
            uint valorTotalDivida,
            uint parcelasDivi,
            uint tipoDivida,
            uint diasdeAtraso,
            uint formadePagamento,
            string memory _localizacao,
            uint tipodeDevedor            
        
        )
    {
        valorTotalDivida = valorTotal;
        parcelasDivi = parcelasDivida;
        tipoDivida = tipo;
        diasdeAtraso = getDiasDeAtrasoDaDivida();
        formadePagamento = formaPagamento;
        _localizacao = localizacao;
        tipodeDevedor = tipoDevedor;   
    }
    
      /**
        @notice Função utilizada para consultar as regras para um lance no leilão
        @return percentualDesconto percentual de Desconto esperado no leilao
        @return quantidadeDeParcelas quantidade de Parcelas esperadas no leilao 
        @return percentualDescontoMax percentual de Desconto limite para lances no leilao
        @return quantidadeDeParcelasMax quantidade de Parcelas limite para lances no leilao 
    */
    function getDadosLanceValor() public view returns
        (
            uint percentualDesconto,
            uint quantidadeDeParcelas,
            uint percentualDescontoMax,
            uint quantidadeDeParcelasMax
        )
    {
        percentualDesconto = percentDesconto;
        quantidadeDeParcelas = quantidadeParcelas;
        percentualDescontoMax = percentDescontoMax;
        quantidadeDeParcelasMax = quantidadeParcelasMax;
    }
    
     /**
        @notice Função utilizada para consultar todos os cronometros necessários na plataforma
        @return tempoMaximoDeVida tempo máximo que um leilão permanecerá em andamento
        @return tempoIniciado o exato momento em que o leilão irá passar de espera para em andamento 
        @return tempoRestante tempo restante de leilão, ou seja, o tempo ainda disponível para lances
        @return tempoRestanteInicializacao tempo que ainda falta para o leilão ser iniciado
        @return tempoRestantePendente tempo restante no estado de pendente 
        @return tempoComecoPendente o exato momento em que o leilão irá passar de andamento para pendente caso não tenha terminado antes
    */
    function getTempo() public view returns( 
        uint tempoMaximoDeVida, 
        uint tempoIniciado,
        uint tempoRestante,
        uint tempoRestanteInicializacao,
        uint tempoRestantePendente,
        uint tempoComecoPendente
        ){
        tempoMaximoDeVida = tempoAtivo;
        tempoIniciado = tempoCriacao + _tempoIniciar; 
        tempoRestante = ((tempoCriacao + _tempoIniciar + tempoAtivo) > now) ? (tempoCriacao + _tempoIniciar + tempoAtivo) - now : 0;
        tempoRestanteInicializacao = ((tempoCriacao + _tempoIniciar) > now) ? (tempoCriacao + _tempoIniciar) - now : 0;
        
        if(leilaoFinalizado() && (_tempoPendente + tempoInicioPendente > now)&&usuarioGanhando.posicaoParticipantes != 0){ 
            
           tempoRestantePendente = (tempoInicioPendente + _tempoPendente) - now;
            
        }else if(leilaoFinalizado() && usuarioGanhando.posicaoParticipantes != 0){
            
                tempoRestantePendente = 0;
        }
        tempoComecoPendente = tempoInicioPendente;
    }
    
     /**
        @notice Função utilizada para verificar se o leilão está finalizado ou não independente do modo de finalização
        @return tempoMaximoDeVida tempo máximo que um leilão permanecerá em andamento
        @return tempoIniciado o exato momento em que o leilão irá passar de espera para em andamento 
        @return tempoRestante tempo restante de leilão, ou seja, o tempo ainda disponível para lances
        @return tempoRestanteInicializacao tempo que ainda falta para o leilão ser iniciado
        @return tempoRestantePendente tempo restante no estado de pendente 
        @return tempoComecoPendente o exato momento em que o leilão irá passar de andamento para pendente caso não tenha terminado antes
    */
    function leilaoFinalizado() public view returns (bool){
        if(opcoesFinalizacao[0].id == modoFinalizacao){
            if(tempoFoiFinalizado() == 2){
                return true;
            }else{
                return false;
            }
        }else if(opcoesFinalizacao[1].id == modoFinalizacao){
            if(usuarioGanhando.posicaoParticipantes != 0){
                return infoParticipante[usuarioGanhando.posicaoParticipantes].indice <= indiceEsperado && infoParticipante[usuarioGanhando.posicaoParticipantes].indice > 0 || tempoFoiFinalizado() == 2;    
            }
            if(tempoFoiFinalizado() == 5){
                return true;
            }else{
                return false;
            }
        }else{
            return finalizado;
        }
    }
       
     /**
        @notice Função utilizada para confirmar a cobrança de uma divida pela empresa vencedora do leilão
        @param sender endereco de um usuário para verificar se quem esta chamando a função é o vencedor do leilão
        @return true se foi concretizada a cobranca corretamente ou false se não foi completada
    */
    function confirmaCobranca(address sender)public returns(bool){
        require(usuarioGanhando.posicaoParticipantes != 0);
        require(infoParticipante[usuarioGanhando.posicaoParticipantes].endereco == sender);
        uint _estado = verificaEstado();
        require(_estado == 2);
        require(!tempoPendenteAcabou());
        
        cobrado = true;
        estado = 4;
        return cobrado;
    }
    
     /**
        @notice Função utilizada para verificar se a dívida foi cobrada ou não

        @return true se a dívida ja foi cobrada ou false se ainda não foi
    */
    function isConfirmado()public view returns(bool){
        return cobrado;
    }
    
     /**
        @notice Função utilizada para cancelar um leilão
        @param sender endereço de um usuário para verificar se quem está chamando a função é o dono do leilão
        @return 
    */
    function cancelaLeilao(address sender)public returns(bool){
        require(sender == dono);
        
        cancelado = true;
        estado = 3;
        diasAtraso = getDiasDeAtrasoDaDivida();
    }
    
    /**
        @notice Função utilizada para verificar se o tempo de pendente acabou ou não
        @return true se to tempo pendente acabou ou false se ainda tem tempo
    */
    function tempoPendenteAcabou() internal view returns(bool){
      require(tempoInicioPendente != 0);
      if(_tempoPendente + tempoInicioPendente > now){  // SE O TEMPO DE PENDENCIA FOR MAIOR QUE O TEMPO ATUAL, É PQ NÃO TERMINOU AINDA
        return false;
      }else{
        return true;
      }
    }
    
    /**
        @notice Função utilizada para reiniciar um leilão caso ninguem tenha ganho ou cobrado. Este leilão não pode ser de modo de finalização manual
        @param sender endereço de um usuário para verificar se quem está chamando a função é o dono do leilão
        @param novoTempo o tempo que o leilão ficará em andamento
        @param novoTempoIniciar depois de quanto tempo o leilão será iniciado
    */
    function reiniciarLeilao(uint novoTempo, address sender,uint novoTempoIniciar)public{
        require(verificaEstado() == 5);
        require(opcoesFinalizacao[2].id != modoFinalizacao);
        require(dono == sender);
        
        tempoAtivo = 0;
        if(novoTempo != 0){
            tempoAtivo = novoTempo;
        }
        
        tempoCriacao = now;
        
        if(novoTempoIniciar != 0){
            _tempoIniciar = novoTempoIniciar;
        }
        
        tempoInicioPendente = tempoCriacao + tempoAtivo + _tempoIniciar;
        
        estado = 0;
    }
    
    /**
        @notice Função utilizada para reiniciar um leilão de modo manual caso ninguem tenha ganho ou cobrado
        @param sender endereço de um usuário para verificar se quem está chamando a função é o dono do leilão
        @param novoTempoIniciar depois de quanto tempo o leilão será iniciado
    */
    function reiniciarLeilaoManual(address sender,uint novoTempoIniciar)public{
        require(opcoesFinalizacao[2].id == modoFinalizacao);
        require(dono == sender);
        
        tempoCriacao = now;
        _tempoIniciar = novoTempoIniciar;
        finalizado = false;
        
        estado = 0;
    }
    
    /**
        @notice Função utilizada para verificar se o tempo terminou retornando o estado em o leilão se encontra
        @return o id do estado em que se encontra o leilão
    */
    function tempoFoiFinalizado() public view returns (uint){
        if(usuarioGanhando.posicaoParticipantes != 0){
            if( (tempoCriacao + tempoAtivo + _tempoIniciar) <= now && !cobrado){
                if(!tempoPendenteAcabou()){
                    return 2;
                }else {
                    return 5;
                }
            }else if(isEstado0()){
                return 0;
            }else if((tempoCriacao + tempoAtivo + _tempoIniciar) >= now && !isEstado0()){
                return 1;
            }
        }else if(isEstado0()){
            return 0;
        }else if((tempoCriacao + _tempoIniciar + tempoAtivo) <= now){
            return 5;
        }else{
            return 1;
        }
            
    }

    /**
        @notice Função utilizada para verificar o estado do leilão
        @dev Para estar no estado 0, o horario de criação do leilão mais o tempo que o leilão deve esperar para iniciar
        deve ser maior que o tempo atual significando que o leilão ainda não iniciou. Para estar no estado 1, o leilão
        não deve estar finalizado, cancelado, pendente ou não ganho e o tempo para iniciar já tem que ter acabado e o de andamento não.
        Para estar no estado 2, algum usuário deve ter dado um lance válido  e o tempo que permanece pendente não pode ter acabado.
        Para estar no estado 3, o leilão está cancelado, ou seja, a variavel estado esta com o conteudo 3, então somente é retornado o estado.
        Para estar no estado 4, em modo manual a variavel vai estar setada como 4, nos outros todos os tempos devem ter terminados
        e a divida deve ter sido cobrada. Para estar no estado 5, o leilao pode ter terminado sem nenhum lance ou a divida não foi cobrada a tempo.
        @return o id do estado atual do leilão 
    */
    function verificaEstado()public view returns(uint){
        if(estado != 3 && estado != 4){
            if( opcoesFinalizacao[2].id == modoFinalizacao ){
                if(isEstado0()){ 
                    return 0;
                }else{
                    if(!leilaoFinalizado()){
                        return 1;
                    }else{
                        if(!tempoPendenteAcabou()){
                            return 2;
                        } else if(!cobrado){
                            return 5;
                        }
                    }
                }
            }else{
                if(isEstado0()){ 
                    return 0;
                }else if( !isIniciandoLeilao() ){
                    if( !leilaoFinalizado() ){
                        if(tempoFoiFinalizado() == 1){ // em andamento
                            return 1;
                        }
                    }else{
                        if(tempoFoiFinalizado() == 2){ // pendente
                            return 2;
                        }
                    }    
                } if((tempoCriacao + tempoAtivo + _tempoIniciar) <= now && tempoPendenteAcabou() && cobrado){ 
                    return 4;
                } if(tempoFoiFinalizado()==5){
                    return 5;
                }
            }
        }
        return estado;
    }
    
    /**
        @notice Função utilizada para verificar se o leilão esta no estado 0, ou seja, ainda não iniciado
        @return true se o leilão ainda não foi iniciado ou false caso esteja em outro estado
    */
    function isEstado0()public view returns(bool){
        return isIniciandoLeilao() && estado != 3 && estado != 4; 
    }
    
    /**
        Função responsavel por retornar se o tempo para iniciar acabou
        
        @return retorna true se o tempo que falta para iniciar o leilao esta em andamento, ou false para se acabou
    */
    function isIniciandoLeilao()public view returns(bool){
        return (tempoCriacao + _tempoIniciar) >= now;
    }
    
    /**
        Função responsavel por retornar se o leilão esta finalizado ou NÃO
        
        @return retorna um booleando que indica se o leilão esta finalizado com o valor true e se não, retorna false
    */
    function isFinalizado() public view returns(bool){
        return finalizado;
    }
    
    /**
        Função responsavel por retornar apenas o endereço da wallet do vencedor
        
        @return retorna o endereço da wallet do vencedor
    */
    function getVencedor() public view returns(address){
        return usuarioGanhando.endereco;
    }
    
    
    /**
        Função utilizada para pegar os dados do vencedor do leilão
        
        @return 'ganhador' é a variavel que retorna o endereco da wallet do usuário
        @return 'lanceDesconto' é a variavel que retorna o lance sobre os descontos
        @return 'lanceParcela' é a variavel que retorna o lance sobre as parcelas
        @return 'lanceIndice' é a variavel que retorna o indice gerado a partir dos lances sobre descontos e parcelas
    */
    function getVencedorDados() public view returns(address ganhador, uint lanceDesconto,uint lanceParcela,uint lanceIndice){
        ganhador = usuarioGanhando.endereco;
        lanceDesconto = infoParticipante[positionParticipante[usuarioGanhando.endereco]].desconto; 
        lanceParcela = infoParticipante[positionParticipante[usuarioGanhando.endereco]].parcelas;
        lanceIndice = infoParticipante[positionParticipante[usuarioGanhando.endereco]].indice;
    }

    /**
        Função utilizada para retornar a quantidade de dias de atraso da dívida da pessoa devedora
        
        @return retorna um inteiro com a quantidade de dias de atraso da divida
    */
    function getDiasDeAtrasoDaDivida() public view returns(uint){
        
        // QUANTIDADE DE SEGUNDOS QUE UM DIA TEM
        uint segundosDeUmDia = 86400; //60 * 60 * 24
        
        uint estadoAtual = verificaEstado();
        
        if(estadoAtual == 3 || estadoAtual == 4){
            return diasAtraso;
        }
        /*  
            TEMPO ATUAL MENOS O TEMPO DE CRIAÇÃO, DIVIDIDO PELOS SEGUNDOS DO DIA, 
            TUDO ISSO MAIS O TEMPO DE ATRASO DA DIVIDA.
            ESTE CALCULO RETORNA O TEMPO DE ATRASO ATUAL DA DÍVIDA.
        */
        return ( ( now - tempoCriacao ) / segundosDeUmDia ) + diasAtraso;
    }
}

