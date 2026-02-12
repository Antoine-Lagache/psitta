/// Notes possibles pour un exercice dans une session SRS.
/// Grade.q correspond à la qualité de la réponse de l'algo SM-2
/// L'algo SM-2 prend une note entre 0 et 5, mais ici,
/// il n'y a que 5 boutons (et non 6), donc aucun Grade pour q=1
enum Grade {
  again(0),
  hard(2),
  medium(3),
  good(4),
  easy(5);

  final int q; // q < 3 <=> Fail
  const Grade(this.q);

  int toInt() => q;
}
