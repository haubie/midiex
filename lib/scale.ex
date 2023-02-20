defmodule Midiex.Scale do

  # See: https://photosounder.com/scales.html

  def cycle(start_note, num_notes, intervals, callback_function) do
    intervals
    |> Enum.drop(1)
    |> Stream.cycle()
    |> Enum.take(num_notes)
    |> Enum.map_reduce(start_note, fn offset, acc ->
      ret = {offset, acc+offset};
      callback_function.(acc);
      ret end)
  end




  # Pentatonic (5)
  def locrian_pentatonic_1, do: [0, 1, 3, 6, 8, 12]
  def locrian_pentatonic_2, do: [0, 3, 4, 6, 10, 12]

  def phrygian_pentatonic, do: [0, 1, 3, 7, 8, 12]
  def syrian_pentatonic, do: [0, 1, 4, 5, 8, 12]
  def scriabin_pentatonic, do: [0, 1, 4, 7, 9, 12]
  @spec altered_pentatonic :: [0 | 1 | 5 | 7 | 9 | 12, ...]
  def altered_pentatonic, do: [0, 1, 5, 7, 9, 12]
  def aeolian_pentatonic, do: [0, 2, 3, 7, 8, 12]

  def dorian_pentatonic, do: [0, 2, 3, 7, 9, 12]

  def major_pentatonic, do: [0, 2, 4, 7, 9, 12]
  def dominant_pentatonic, do: [0, 2, 4, 7, 10, 12]

  def scottish_pentatonic, do: [0, 2, 5, 7, 9, 12]
  def blues_major, do: scottish_pentatonic()
  def major_complement, do: scottish_pentatonic()

  def suspended_pentatonic, do: [0, 2, 5, 7, 10, 12]

  def minor_added_sixth_pentatonic, do: [0, 3, 5, 7, 9, 12]

  def minor_pentatonic, do: [0, 3, 5, 7, 10, 12]
  def blues_pentatonic, do: minor_pentatonic()

  def blues_minor, do: [0, 3, 5, 8, 10, 12]
  def man_gong, do: blues_minor()

  def mixolydian_pentatonic, do: [0, 4, 5, 7, 10, 12]

  def ionian_pentatonic, do: [0, 4, 5, 7, 11, 12]

  def bacovia_romania, do: [0, 4, 5, 8, 11, 12]

  def lydian_pentatonic, do: [0, 4, 6, 7, 11, 12]


  # Hexatonic (6)

  @doc "Messiaen mode 5, Two-semitone Tritone scale"
  def messiaen, do: [0, 1, 2, 6, 7, 8, 12]
  def istrian, do: [0, 1, 3, 4, 6, 7, 12]
  def superlocrian_hexamirror, do: [0, 1, 3, 4, 6, 10, 12]
  def double_phrygian_hexatonic, do: [0, 1, 3, 5, 6, 9, 12]
  def messiaen_truncated_mode_2, do: [0, 1, 3, 6, 7, 9, 12]
  def messiaen_truncated_mode_3, do:  [0, 1, 4, 5, 8, 9, 12]
  def prometheus_liszt, do: messiaen_truncated_mode_3()
  def messiaen_truncated_mode_2_tritone, do: [0, 1, 4, 6, 7, 10, 12]
  def prometheus_neapolitan, do: [0, 1, 4, 6, 9, 10, 12]
  def pyramid_hexatonic, do: [0, 2, 3, 5, 6, 9, 12]
  def minor_hexatonic, do: [0, 2, 3, 5, 7, 10, 12]
  def hawaiian, do: [0, 2, 3, 7, 9, 11, 12]
  def arezzo_major_diatonic_hexachord, do: [0, 2, 4, 5, 7, 9, 12]
  def scottish_hexatonic, do: arezzo_major_diatonic_hexachord()
  def ancient_chinese, do: [0, 2, 4, 6, 7, 9, 12]
  def whole_tone, do: [0, 2, 4, 6, 8, 10, 12]
  def messiaen_mode_1, do: whole_tone()
  def anhemitonic_hexatonic, do: whole_tone()
  def prometheus_scriabin, do: [0, 2, 4, 6, 9, 10, 12]
  def mystic, do: prometheus_scriabin()
  def lydian_hexatonic, do: [0, 2, 4, 7, 9, 11, 12]
  def mixolydian_hexatonic, do: [0, 2, 5, 7, 9, 10, 12]
  def equal_temperaments_3_and_4_mixed, do: [0, 3, 4, 6, 8, 9, 12]
  def messiaen_truncated_mode_3_inverse, do: [0, 3, 4, 7, 8, 11, 12]
  def major_augmented, do: messiaen_truncated_mode_3_inverse()
  def genus_tertium, do: messiaen_truncated_mode_3_inverse()
  def blues_scale_i, do: [0, 3, 5, 6, 7, 10, 12]
  @spec phrygian_hexatonic :: [0 | 3 | 5 | 7 | 8 | 10 | 12, ...]
  def phrygian_hexatonic, do: [0, 3, 5, 7, 8, 10, 12]
  def messiaen_mode_5_inverse, do: [0, 4, 5, 6, 10, 11, 12]
  def genus_secundum, do: [0, 4, 5, 7, 9, 11, 12]



  # Common
  # def major, do: [0, 2, 2, 1, 2, 2, 2, 1]
  def major, do: [0, 2, 4, 5, 7, 9, 11, 12]


  # Intervals

  def dorian, do: [2,1,2,2,2,1,2]
  def phrygian, do: [1,2,2,2,1,2,2]
  def lydian, do: [2,2,2,1,2,2,1]
  def mixolydian, do: [2,2,1,2,2,1,2]
  def aeolian, do: [2,1,2,2,1,2,2]
  def locrian, do: [1,2,2,1,2,2,2]

  def lydian_domiant, do: [2,2,2,1,2,1,2]
  def super_locrian, do: [1,2,1,2,2,2,2]

  def minor_pentatonic, do: [3,2,2,3,2]
  def major_pentatonic, do: [2,2,3,2,3]
  def minor_blues, do: [3,2,1,1,3,2]
  def major_blues, do: [2,1,1,3,2,3]

  def whole_half_diminished, do: [2,1,2,1,2,1,2,1]
  def half_whole_diminished, do: [1,2,1,2,1,2,1,2]




  # Heptatonic (7)






# [0, 1, 2, 4, 6, 8, 10, 12]	Leading Whole-tone inverse
# [0, 1, 2, 4, 7, 8, 9, 12]	Chromatic Phrygian inverse
# [0, 1, 2, 5, 6, 7, 9, 12]	Chromatic Hypophrygian inverse
# [0, 1, 2, 5, 6, 7, 10, 12]	Chromatic Mixolydian
# [0, 1, 2, 5, 7, 8, 9, 12]	Chromatic Dorian
# [0, 1, 3, 4, 6, 8, 9, 12]	Ultralocrian, Superlocrian Diminished, Mixolydian sharp 1
# [0, 1, 3, 4, 6, 8, 10, 12]	Superlocrian, Altered Dominant, Diminished Whole-tone, Locrian flat 4, Pomeroy, Ravel
# [0, 1, 3, 4, 7, 8, 10, 12]	Phrygian flat 4
# [0, 1, 3, 5, 6, 8, 9, 12]	Locrian double-flat 7
# [0, 1, 3, 5, 6, 8, 10, 12]	Greek Mixolydian, Greek Hyperdorian, Medieval Hypophrygian, Medieval Locrian, Greek Medieval Hyperaeolian, Rut biscale descending
# [0, 1, 3, 5, 6, 9, 10, 12]	Locrian natural 6
# [0, 1, 3, 5, 7, 8, 10, 12]	Greek Dorian, Medieval Phrygian, Greek Medieval Hypoaeolian, Gregorian nr.3, Major inverse
# [0, 1, 3, 5, 7, 8, 11, 12]	Neapolitan Minor, Hungarian Gipsy
# [0, 1, 3, 5, 7, 9, 10, 12]	Jazz Minor inverse, Phrygian-Mixolydian, Dorian flat 2
# [0, 1, 3, 5, 7, 9, 11, 12]	Neapolitan Major, Lydian Major
# [0, 1, 3, 6, 7, 8, 11, 12]	Harsh Minor, Chromatic Lydian inverse
# [0, 1, 4, 5, 6, 8, 11, 12]	Persian, Chromatic Hypolydian inverse
# [0, 1, 4, 5, 6, 9, 10, 12]	Oriental, Hungarian Minor inverse
# [0, 1, 4, 5, 6, 9, 11, 12]	Chromatic Lydian, Bhankar
# [0, 1, 4, 5, 7, 8, 9, 12]	Gipsy Hexatonic
# [0, 1, 4, 5, 7, 8, 10, 12]	Phrygian Dominant, Phrygian Major, Spanish Gipsy, Dorico Flamenco: Spain, Harmonic Major inverse
# [0, 1, 4, 5, 7, 8, 11, 12]	Major Gipsy, Double Harmonic Major, Chromatic 2nd Byzantine Liturgical
# [0, 1, 4, 5, 7, 9, 10, 12]	Harmonic Minor inverse
# [0, 1, 4, 5, 7, 9, 11, 12]	Major-Melodic Phrygian, Hungarian Gipsy inverse
# [0, 1, 4, 5, 8, 10, 11, 12]	Verdi's Scala enigmatica descending
# [0, 1, 4, 6, 7, 8, 9, 12]	Foulds' Mantra of Will scale
# [0, 1, 4, 6, 7, 8, 10, 12]	Harsh Major-Minor
# [0, 1, 4, 6, 7, 8, 11, 12]	Chromatic Hypolydian
# [0, 1, 4, 6, 7, 9, 10, 12]	Romanian Major, Petrushka chord
# [0, 1, 4, 6, 7, 9, 11, 12]	Harsh-intense Major
# [0, 1, 4, 6, 8, 10, 11, 12]	Verdi's Scala enigmatica ascending
# [0, 2, 3, 4, 5, 6, 9, 12]	Debussy's Heptatonic
# [0, 2, 3, 4, 7, 8, 9, 12]	Chromatic Hypodorian, Relative Blues scale
# [0, 2, 3, 5, 6, 7, 10, 12]	Modified Blues
# [0, 2, 3, 5, 6, 8, 9, 12]	Moravian Pistalkova, Hungarian Major inverse
# [0, 2, 3, 5, 6, 8, 10, 12]	Minor Locrian, Half Diminished, Locrian sharp 2, Minor flat 5
# [0, 2, 3, 5, 6, 8, 11, 12]	Locrian nr.2
# [0, 2, 3, 5, 6, 9, 10, 12]	Dorian flat 5, Blues Heptatonic
# [0, 2, 3, 5, 6, 9, 11, 12]	Jeths' mode
# [0, 2, 3, 5, 7, 8, 10, 12]	Natural Minor
# [0, 2, 3, 5, 7, 8, 11, 12]	Harmonic Minor
# [0, 2, 3, 5, 7, 9, 10, 12]	Greek Phrygian, Medieval Dorian, Medieval Hypomixolydian, Gregorian nr.8, Eskimo Heptatonic
# [0, 2, 3, 5, 7, 9, 11, 12]	Melodic Minor ascending, Jazz Minor, Minor-Major, Hawaiian
# [0, 2, 3, 6, 7, 8, 10, 12]	Minor Gipsy, Ukrainian Dorian
# [0, 2, 3, 6, 7, 8, 11, 12]	Double Harmonic Minor, Hungarian Minor, Egyptian Heptatonic, Flamenco Mode
# [0, 2, 3, 6, 7, 9, 10, 12]	Tunisian, Dorian sharp 4, Ukrainian Minor, Kaffa, Gnossiennes
# [0, 2, 3, 6, 7, 9, 11, 12]	Lydian Diminished
# [0, 2, 4, 5, 6, 8, 10, 12]	Major Locrian
# [0, 2, 4, 5, 6, 9, 10, 12]	Minor Gipsy inverse
# [0, 2, 4, 5, 7, 8, 9, 12]	Major Bebop Heptatonic
# [0, 2, 4, 5, 7, 8, 10, 12]	Major-Minor, Melodic Major, Mixolydian flat 6
# [0, 2, 4, 5, 7, 8, 11, 12]	Harmonic Major
# [0, 2, 4, 5, 7, 9, 10, 12]	Greek Hypophrygian, Greek Ionian (Iastian), Medieval Mixolydian, Greek Medieval Hypoionian, Gregorian nr.7, Enharmonic Byzantine Liturgical
# [0, 2, 4, 5, 7, 9, 11, 12]	Major
# [0, 2, 4, 5, 8, 9, 11, 12]	Ionian Augmented, Ionian sharp 5
# [0, 2, 4, 6, 7, 8, 10, 12]	Lydian Minor
# [0, 2, 4, 6, 7, 8, 11, 12]	Harmonic Lydian
# [0, 2, 4, 6, 7, 9, 10, 12]	Lydian Dominant, Overtone, Lydian-Mixolydian, Bartok
# [0, 2, 4, 6, 7, 9, 11, 12]	Greek Hypolydian, Medieval Lydian, Greek Medieval Hypolocrian, Rut biscale ascending
# [0, 2, 4, 6, 8, 9, 11, 12]	Lydian Augmented, Lydian sharp 5
# [0, 2, 4, 6, 8, 10, 11, 12]	Leading Whole-tone
# [0, 2, 5, 6, 7, 10, 11, 12]	Chromatic Mixolydian inverse
# [0, 3, 4, 5, 7, 8, 11, 12]	Gipsy Hexatonic inverse
# [0, 3, 4, 5, 7, 9, 10, 12]	Bluesy Rock 'n Roll
# [0, 3, 4, 5, 7, 10, 11, 12]	Chromatic Dorian inverse
# [0, 3, 4, 5, 8, 9, 10, 12]	Chromatic Hypodorian inverse
# [0, 3, 4, 5, 8, 10, 11, 12]	Chromatic Phrygian
# [0, 3, 4, 6, 7, 9, 10, 12]	Hungarian Major
# [0, 3, 4, 6, 7, 9, 11, 12]	Aeolian Harmonic, Lydian sharp 2
# [0, 3, 4, 6, 8, 9, 11, 12]	Aeolian flat 1
# [0, 3, 5, 6, 7, 9, 10, 12]	Blues Heptatonic II
# [0, 3, 5, 6, 7, 10, 11, 12]	Chromatic Hypophrygian, Blues scale III



end
