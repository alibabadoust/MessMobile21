class LeaderboardModel {
  final String adsoyad;
  final int skor;

  LeaderboardModel({
    required this.adsoyad,
    required this.skor,
  });

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardModel(
      adsoyad: json['adsoyad'] as String,
      skor: json['skor'] as int,
    );
  }
}
