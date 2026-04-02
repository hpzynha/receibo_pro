class Recibo {
  int? id;
  String numeracao;
  String prestadorNome;
  String prestadorCpf;
  String clienteNome;
  String servico;
  double valor;
  DateTime data;
  String? observacoes; // TODO: PRO
  String? logoPath; // TODO: PRO
  String tema; // "minimalista" | "classico" | "colorido" — TODO: PRO
  DateTime criadoEm;

  Recibo({
    this.id,
    required this.numeracao,
    required this.prestadorNome,
    required this.prestadorCpf,
    required this.clienteNome,
    required this.servico,
    required this.valor,
    required this.data,
    this.observacoes,
    this.logoPath,
    this.tema = 'minimalista',
    required this.criadoEm,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numeracao': numeracao,
      'prestador_nome': prestadorNome,
      'prestador_cpf': prestadorCpf,
      'cliente_nome': clienteNome,
      'servico': servico,
      'valor': valor,
      'data': data.toIso8601String(),
      'observacoes': observacoes,
      'logo_path': logoPath,
      'tema': tema,
      'criado_em': criadoEm.toIso8601String(),
    };
  }

  factory Recibo.fromMap(Map<String, dynamic> map) {
    return Recibo(
      id: map['id'] as int?,
      numeracao: map['numeracao'] as String,
      prestadorNome: map['prestador_nome'] as String,
      prestadorCpf: map['prestador_cpf'] as String,
      clienteNome: map['cliente_nome'] as String,
      servico: map['servico'] as String,
      valor: (map['valor'] as num).toDouble(),
      data: DateTime.parse(map['data'] as String),
      observacoes: map['observacoes'] as String?,
      logoPath: map['logo_path'] as String?,
      tema: map['tema'] as String? ?? 'minimalista',
      criadoEm: DateTime.parse(map['criado_em'] as String),
    );
  }

  Recibo copyWith({
    int? id,
    String? numeracao,
    String? prestadorNome,
    String? prestadorCpf,
    String? clienteNome,
    String? servico,
    double? valor,
    DateTime? data,
    String? observacoes,
    String? logoPath,
    String? tema,
    DateTime? criadoEm,
  }) {
    return Recibo(
      id: id ?? this.id,
      numeracao: numeracao ?? this.numeracao,
      prestadorNome: prestadorNome ?? this.prestadorNome,
      prestadorCpf: prestadorCpf ?? this.prestadorCpf,
      clienteNome: clienteNome ?? this.clienteNome,
      servico: servico ?? this.servico,
      valor: valor ?? this.valor,
      data: data ?? this.data,
      observacoes: observacoes ?? this.observacoes,
      logoPath: logoPath ?? this.logoPath,
      tema: tema ?? this.tema,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }
}
