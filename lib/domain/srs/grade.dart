/// Notes possibles pour un exercice dans une session SRS.
enum Grade {
  again,
  hard,
  medium,
  good,
  easy,
}

/// Convertit une note Grade en entier pour traitement SRS.
/// le int correspond à la valeur q qualité de la réponse de l'algo SM-2
/// L'algo SM-2 prend une note entre 0 et 5, mais ici, il n'y a que 5 boutons (et non 6), donc rien pour q=1
int gradeToInt(Grade grade) {
  switch (grade) {
    case Grade.again:
      return 0;
    case Grade.hard:
      return 2;
    case Grade.medium:
      return 3;
    case Grade.good:
      return 4 ;
    case Grade.easy:
      return 5;
  }
}