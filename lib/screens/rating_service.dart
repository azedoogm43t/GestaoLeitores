import 'dart:math';

import 'package:gestao_leitores/models/presenca_model.dart';
import 'package:gestao_leitores/services/firestore_service.dart';

class LeitorRating {
  final String leitorId;
  final String nome;
  final int avaliacoes; // nº de presenças válidas
  final double media;   // média final 0–10
  final double mediaDiccao;
  final double mediaColocacaoVoz;
  final double mediaSinaisPontuacao;
  final double mediaRitmo;
  final double mediaEnsaio; // 0..10 (ensaio é binário, true=10, false=0)

  const LeitorRating({
    required this.leitorId,
    required this.nome,
    required this.avaliacoes,
    required this.media,
    required this.mediaDiccao,
    required this.mediaColocacaoVoz,
    required this.mediaSinaisPontuacao,
    required this.mediaRitmo,
    required this.mediaEnsaio,
  });
}

class RatingService {
  final FirestoreService _fs;
  RatingService(this._fs);

  // Pesos (somam 1.0). Ajusta à vontade.
  static const double wDiccao = 0.20;
  static const double wVoz    = 0.20;
  static const double wSinais = 0.20;
  static const double wRitmo  = 0.20;
  static const double wEnsaio = 0.20;

  bool _contaParaRanking(PresencaModel p) {
    final temNotas = (p.diccao > 0) || (p.colocacaoVoz > 0) || (p.sinaisPontuacao > 0) || (p.ritmo > 0);
    final avaliacaoMissa  = p.presenteMissa && temNotas;
    final avaliacaoEnsaio = p.presenteEnsaio; // binário
    return avaliacaoMissa || avaliacaoEnsaio;
  }

  double _scorePresenca(PresencaModel p) {
    final ensaioScore = p.presenteEnsaio ? 10.0 : 0.0;
    return p.diccao * wDiccao +
           p.colocacaoVoz * wVoz +
           p.sinaisPontuacao * wSinais +
           p.ritmo * wRitmo +
           ensaioScore * wEnsaio;
  }

  Future<List<LeitorRating>> getLeaderboardOnce() async {
    final presencas = await _fs.getPresencas().first; // Stream -> valor único
    final leitores  = await _fs.getLeitores().first;

    final nomes = { for (final l in leitores) l.id: l.nome };

    final Map<String, _Agg> agg = {};
    for (final p in presencas) {
      if (!_contaParaRanking(p)) continue;

      final a = agg.putIfAbsent(p.leitorId, () => _Agg());
      a.count++;
      a.sumDiccao += p.diccao;
      a.sumVoz += p.colocacaoVoz;
      a.sumSinais += p.sinaisPontuacao;
      a.sumRitmo += p.ritmo;
      a.sumEnsaio += p.presenteEnsaio ? 10.0 : 0.0;
      a.sumScore += _scorePresenca(p);
    }

    final out = <LeitorRating>[];
    agg.forEach((id, a) {
      final c = max(a.count, 1);
      out.add(LeitorRating(
        leitorId: id,
        nome: nomes[id] ?? 'Leitor',
        avaliacoes: a.count,
        media: a.sumScore / c,
        mediaDiccao: a.sumDiccao / c,
        mediaColocacaoVoz: a.sumVoz / c,
        mediaSinaisPontuacao: a.sumSinais / c,
        mediaRitmo: a.sumRitmo / c,
        mediaEnsaio: a.sumEnsaio / c,
      ));
    });

    // ordenar: média desc, depois nº avaliações, depois nome
    out.sort((a, b) {
      final byMedia = b.media.compareTo(a.media);
      if (byMedia != 0) return byMedia;
      final byCount = b.avaliacoes.compareTo(a.avaliacoes);
      if (byCount != 0) return byCount;
      return a.nome.compareTo(b.nome);
    });

    return out;
  }

  Future<LeitorRating?> getBestOnce() async {
    final list = await getLeaderboardOnce();
    return list.isEmpty ? null : list.first;
  }

  Future<LeitorRating?> getWorstOnce() async {
    final list = await getLeaderboardOnce();
    return list.isEmpty ? null : list.last;
  }
}

class _Agg {
  int count = 0;
  double sumDiccao = 0;
  double sumVoz = 0;
  double sumSinais = 0;
  double sumRitmo = 0;
  double sumEnsaio = 0;
  double sumScore = 0;
}
