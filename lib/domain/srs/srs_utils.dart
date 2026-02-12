   
/// renvoie le nombre de jours de d avec précision en Microsecondes
double durationToDays(Duration duration) => duration.inMicroseconds / Duration.microsecondsPerDay;

/// renvoie la duration correspondant aux nombres de jours d
Duration daysToduration(double days){
  return Duration(microseconds: (days *Duration.microsecondsPerDay).round());
}