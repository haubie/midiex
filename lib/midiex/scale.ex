defmodule Midiex.Scale do

  # See: https://photosounder.com/scales.html


  # Ported from Sonic Pi
  # https://github.com/sonic-pi-net/sonic-pi/blob/710107fe22c5977b9fa5e83b71e30f847610e240/app/server/ruby/lib/sonicpi/scale.rb
  # which was ported from Overtine
  # https://github.com/overtone/overtone/blob/master/src/overtone/music/pitch.clj



  # Most of makams consists of one "besli" and one "dortlu"
  # In addition they make 22 + 31 = 53 koma, which is one octave.
  # Since scales consists (54 / 9) * 2 = 12 steps, we need correction.
  # So, an error corrected koma should be 12.0 / 53 not 2.0 / 9.
  # This creates a little amount of dissonance for notes which are not octave of the base note.

  @koma            12.0 / 53
  @bakiyye         4 * @koma
  @kucuk_mucenneb  5 * @koma
  @buyuk_mucenneb  8 * @koma
  @tanini          9 * @koma
  @artik_ikili     12 * @koma

  @ionian_sequence     [2, 2, 1, 2, 2, 2, 1]
  @hex_sequence        [2, 2, 1, 2, 2, 3]
  @pentatonic_sequence [3, 2, 2, 3, 2]
  # Basic "dortlu"
  @cargah_dortlusu        [@tanini, @tanini, @bakiyye]
  @buselik_dortlusu       [@tanini, @bakiyye, @tanini]
  @kurdi_dortlusu         [@bakiyye, @tanini, @tanini]
  @rast_dortlusu          [@tanini, @buyuk_mucenneb, @kucuk_mucenneb]
  @ussak_dortlusu         [@buyuk_mucenneb, @kucuk_mucenneb, @tanini]
  @hicaz_dortlusu         [@kucuk_mucenneb, @artik_ikili, @kucuk_mucenneb]
  # Basic "besli"
  @cargah_beslisi         @cargah_dortlusu ++ [@tanini]
  @buselik_beslisi        @buselik_dortlusu ++ [@tanini]
  @rast_beslisi           @rast_dortlusu ++ [@tanini]
  @huseyni_beslisi        [@buyuk_mucenneb, @kucuk_mucenneb, @tanini, @tanini]
  @hicaz_beslisi          @hicaz_dortlusu ++ [@tanini]
  # Other "dortlu" and "besli"
  @segah_dortlusu         [@kucuk_mucenneb, @tanini, @buyuk_mucenneb]
  @tam_segah_beslisi      @segah_dortlusu ++ [@tanini]
  @eksik_segah_beslisi    @segah_dortlusu ++ [@kucuk_mucenneb]
  @mustear_dortlusu       [@tanini, @kucuk_mucenneb, @buyuk_mucenneb]
  @huzzam_beslisi         [@kucuk_mucenneb, @tanini, @kucuk_mucenneb, @artik_ikili]
  @nikriz_beslisi         [@tanini, @kucuk_mucenneb, @artik_ikili, @kucuk_mucenneb]
  @tam_ferahnak_beslisi   [@kucuk_mucenneb, @tanini, @tanini, @buyuk_mucenneb]
  @eksik_ferahnak_beslisi [@kucuk_mucenneb, @tanini, @tanini, @bakiyye]

  # currently unused
  # @nisabur_dortlusu       [@buyuk_mucenneb, @kucuk_mucenneb, @tanini]
  # @kurdi_beslisi          @kurdi_dortlusu ++ [@tanini]
  # @saba_dortlusu          [@buyuk_mucenneb, @kucuk_mucenneb, @kucuk_mucenneb]
  # @tam_mustear_beslisi    @mustear_dortlusu ++ [@tanini]
  # @eksik_mustear_beslisi  @mustear_dortlusu ++ [@kucuk_mucenneb]
  # @pencgah_beslisi        [@tanini, @tanini, @buyuk_mucenneb, @kucuk_mucenneb]
  # @nisabur_beslisi        @nisabur_dortlusu ++ [@bakiyye]


  @rotate fn seq, num ->
    {h, t} = Enum.split(seq, num)
    t ++ h
  end

  @scale_intervals [

      diatonic:           @ionian_sequence,
      ionian:             @ionian_sequence,
      major:              @ionian_sequence,
      dorian:             @rotate.(@ionian_sequence, 1),
      phrygian:           @rotate.(@ionian_sequence, 2),
      lydian:             @rotate.(@ionian_sequence, 3),
      mixolydian:         @rotate.(@ionian_sequence, 4),
      aeolian:            @rotate.(@ionian_sequence, 5),
      minor:              @rotate.(@ionian_sequence, 5),
      locrian:            @rotate.(@ionian_sequence, 6),
      hex_major6:         @hex_sequence,
      hex_dorian:         @rotate.(@hex_sequence, 1),
      hex_phrygian:       @rotate.(@hex_sequence, 2),
      hex_major7:         @rotate.(@hex_sequence, 3),
      hex_sus:            @rotate.(@hex_sequence, 4),
      hex_aeolian:        @rotate.(@hex_sequence, 5),
      minor_pentatonic:   @pentatonic_sequence,
      yu:                 @pentatonic_sequence,
      major_pentatonic:   @rotate.(@pentatonic_sequence, 1),
      gong:               @rotate.(@pentatonic_sequence, 1),
      egyptian:           @rotate.(@pentatonic_sequence, 2),
      shang:              @rotate.(@pentatonic_sequence, 2),
      jiao:               @rotate.(@pentatonic_sequence, 3),
      zhi:                @rotate.(@pentatonic_sequence, 4),
      ritusen:            @rotate.(@pentatonic_sequence, 4),
      whole_tone:         [2, 2, 2, 2, 2, 2],
      whole:              [2, 2, 2, 2, 2, 2],
      chromatic:          [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      harmonic_minor:     [2, 1, 2, 2, 1, 3, 1],
      melodic_minor_asc:  [2, 1, 2, 2, 2, 2, 1],
      hungarian_minor:    [2, 1, 3, 1, 1, 3, 1],
      octatonic:          [2, 1, 2, 1, 2, 1, 2, 1],
      messiaen1:          [2, 2, 2, 2, 2, 2],
      messiaen2:          [1, 2, 1, 2, 1, 2, 1, 2],
      messiaen3:          [2, 1, 1, 2, 1, 1, 2, 1, 1],
      messiaen4:          [1, 1, 3, 1, 1, 1, 3, 1],
      messiaen5:          [1, 4, 1, 1, 4, 1],
      messiaen6:          [2, 2, 1, 1, 2, 2, 1, 1],
      messiaen7:          [1, 1, 1, 2, 1, 1, 1, 1, 2, 1],
      super_locrian:      [1, 2, 1, 2, 2, 2, 2],
      hirajoshi:          [2, 1, 4, 1, 4],
      kumoi:              [2, 1, 4, 2, 3],
      neapolitan_major:   [1, 2, 2, 2, 2, 2, 1],
      bartok:             [2, 2, 1, 2, 1, 2, 2],
      bhairav:            [1, 3, 1, 2, 1, 3, 1],
      locrian_major:      [2, 2, 1, 1, 2, 2, 2],
      ahirbhairav:        [1, 3, 1, 2, 2, 1, 2],
      enigmatic:          [1, 3, 2, 2, 2, 1, 1],
      neapolitan_minor:   [1, 2, 2, 2, 1, 3, 1],
      pelog:              [1, 2, 4, 1, 4],
      augmented2:         [1, 3, 1, 3, 1, 3],
      scriabin:           [1, 3, 3, 2, 3],
      harmonic_major:     [2, 2, 1, 2, 1, 3, 1],
      melodic_minor_desc: [2, 1, 2, 2, 1, 2, 2],
      romanian_minor:     [2, 1, 3, 1, 2, 1, 2],
      hindu:              [2, 2, 1, 2, 1, 2, 2],
      iwato:              [1, 4, 1, 4, 2],
      melodic_minor:      [2, 1, 2, 2, 2, 2, 1],
      diminished2:        [2, 1, 2, 1, 2, 1, 2, 1],
      marva:              [1, 3, 2, 1, 2, 2, 1],
      melodic_major:      [2, 2, 1, 2, 1, 2, 2],
      indian:             [4, 1, 2, 3, 2],
      spanish:            [1, 3, 1, 2, 1, 2, 2],
      prometheus:         [2, 2, 2, 5, 1],
      diminished:         [1, 2, 1, 2, 1, 2, 1, 2],
      todi:               [1, 2, 3, 1, 1, 3, 1],
      leading_whole:      [2, 2, 2, 2, 2, 1, 1],
      augmented:          [3, 1, 3, 1, 3, 1],
      purvi:              [1, 3, 2, 1, 1, 3, 1],
      chinese:            [4, 2, 1, 4, 1],
      lydian_minor:       [2, 2, 2, 1, 1, 2, 2],
      blues_major:        [2, 1, 1, 3, 2, 3],
      blues_minor:        [3, 2, 1, 1, 3, 2],
      # Basic makams
      cargah:             @cargah_beslisi ++ @cargah_dortlusu,
      buselik:            @buselik_beslisi ++ @kurdi_dortlusu,
      buselik_2:          @buselik_beslisi ++ @hicaz_dortlusu,
      kurdi:              @kurdi_dortlusu ++ @buselik_beslisi,
      rast:               @rast_beslisi ++ @rast_dortlusu,
      acemli_rast:        @rast_beslisi ++ @buselik_dortlusu,
      ussak:              @ussak_dortlusu ++ @buselik_beslisi,
      bayati:             @ussak_dortlusu ++ @buselik_beslisi,
      bayati_2:           @ussak_dortlusu ++ @buselik_beslisi ++ @kurdi_dortlusu,
      isfahan:            @ussak_dortlusu ++ @buselik_beslisi,
      isfahan_2:          @ussak_dortlusu ++ @buselik_beslisi ++ @kurdi_dortlusu,
      hicaz_humayun:      @hicaz_dortlusu ++ @buselik_beslisi,
      hicaz_humayun_2:    @hicaz_dortlusu ++ @buselik_beslisi ++ @kurdi_dortlusu,
      hicaz:              @hicaz_dortlusu ++ @rast_beslisi,
      hicaz_2:            @hicaz_dortlusu ++ @rast_beslisi ++ @buselik_dortlusu,
      uzzal:              @hicaz_beslisi ++ @ussak_dortlusu,
      uzzal_2:            @hicaz_beslisi ++ @ussak_dortlusu ++ @buselik_beslisi,
      zirguleli_hicaz:    @hicaz_beslisi ++ @hicaz_dortlusu,
      zirguleli_hicaz_2:  @hicaz_beslisi ++ @hicaz_dortlusu ++ @buselik_beslisi,
      huseyni:            @huseyni_beslisi ++ @ussak_dortlusu,
      huseyni_2:          @huseyni_beslisi ++ @ussak_dortlusu ++ @buselik_beslisi,
      muhayyer:           @huseyni_beslisi ++ @ussak_dortlusu,
      gulizar:            @huseyni_beslisi ++ @ussak_dortlusu,
      neva:               @ussak_dortlusu ++ @rast_beslisi,
      neva_2:             @ussak_dortlusu ++ @rast_beslisi ++ @buselik_dortlusu,
      tahir:              @ussak_dortlusu ++ @rast_beslisi,
      tahir_2:            @ussak_dortlusu ++ @rast_beslisi ++ @buselik_dortlusu,
      karcigar:           @ussak_dortlusu ++ @hicaz_beslisi,
      suznak:             @rast_beslisi ++ @hicaz_dortlusu,
      suznak_2:           @rast_beslisi ++ @hicaz_dortlusu ++ @buselik_beslisi,
      # Sedd Makams
      mahur:              @cargah_beslisi ++ @cargah_dortlusu,
      acem_asiran:        @cargah_beslisi ++ @cargah_dortlusu,
      nihavend:           @buselik_beslisi ++ @kurdi_dortlusu,
      nihavend_2:         @buselik_beslisi ++ @hicaz_dortlusu,
      sultani_yegah:      @buselik_beslisi ++ @kurdi_dortlusu,
      sultani_yegah_2:    @buselik_beslisi ++ @hicaz_dortlusu,
      kurdili_hicazkar:   @kurdi_dortlusu ++ @buselik_beslisi,
      kurdili_hicazkar_2: @kurdi_dortlusu ++ @hicaz_dortlusu ++ @buselik_beslisi,
      kurdili_hicazkar_3: @kurdi_dortlusu ++ @hicaz_dortlusu ++ @hicaz_beslisi,
      kurdili_hicazkar_4: @kurdi_dortlusu ++ @ussak_dortlusu ++ @buselik_beslisi,
      kurdili_hicazkar_5: @kurdi_dortlusu ++ @ussak_dortlusu ++ @ussak_dortlusu,
      zirguleli_suznak:   @hicaz_beslisi ++ @hicaz_dortlusu,
      zirguleli_suznak_2: @hicaz_beslisi ++ @hicaz_dortlusu ++ @buselik_beslisi,
      zirguleli_suznak_3: @hicaz_beslisi ++ @hicaz_dortlusu ++ @hicaz_beslisi,
      hicazkar:           @hicaz_beslisi ++ @hicaz_dortlusu,
      hicazkar_2:         @hicaz_beslisi ++ @hicaz_dortlusu ++ @buselik_beslisi,
      evcara:             @hicaz_beslisi ++ @hicaz_dortlusu,
      evcara_2:           @hicaz_beslisi ++ @hicaz_dortlusu ++ @mustear_dortlusu,
      evcara_3:           @hicaz_beslisi ++ @hicaz_dortlusu ++ @eksik_ferahnak_beslisi,
      evcara_4:           @hicaz_beslisi ++ @hicaz_dortlusu ++ @eksik_segah_beslisi,
      suzidil:            @hicaz_beslisi ++ @hicaz_dortlusu,
      suzidil_2:          @hicaz_beslisi ++ @hicaz_dortlusu ++ @hicaz_beslisi ++ @kurdi_dortlusu,
      sedaraban:          @hicaz_beslisi ++ @hicaz_dortlusu,
      sedaraban_2:        @hicaz_beslisi ++ @hicaz_dortlusu ++ @hicaz_dortlusu ++ @buselik_beslisi,
      segah:              @tam_segah_beslisi ++ @hicaz_dortlusu, # There should be more variations of segah
      segah_2:            [@kucuk_mucenneb, @tanini] ++ @ussak_dortlusu ++ @buselik_beslisi,
      huzzam:             @huzzam_beslisi ++ @hicaz_dortlusu,
      huzzam_2:           [@kucuk_mucenneb, @tanini] ++ @hicaz_dortlusu ++ @buselik_beslisi,
      bayati_araban:      @ussak_dortlusu ++ @hicaz_beslisi ++ @kurdi_dortlusu,
      acem_kurdi:         @kurdi_dortlusu ++ @cargah_beslisi,
      sehnaz:             @hicaz_dortlusu ++ @buselik_beslisi,
      sehnaz_2:           @hicaz_dortlusu ++ @rast_beslisi,
      sehnaz_3:           @hicaz_beslisi ++ @ussak_dortlusu,
      sehnaz_4:           @hicaz_beslisi ++ @hicaz_dortlusu, # There should be more variations of sehnaz
      saba:               [@buyuk_mucenneb, @kucuk_mucenneb] ++ @hicaz_beslisi ++ @hicaz_dortlusu,
      dugah:              [@buyuk_mucenneb, @kucuk_mucenneb] ++ @hicaz_beslisi ++ @hicaz_dortlusu,
      dugah_2:            @hicaz_beslisi ++ @hicaz_dortlusu,
      evic:               @segah_dortlusu, # There should be more variations of evic
      evic_2:             @eksik_segah_beslisi,
      bestenigar:         @segah_dortlusu ++ [@kucuk_mucenneb] ++ @hicaz_beslisi ++ @hicaz_dortlusu,
      ferahnak:           @tam_ferahnak_beslisi ++ @hicaz_dortlusu, # There should be more variations of ferahnak
      sevkefza:           @cargah_beslisi ++ @cargah_dortlusu,
      sevkefza_2:         @cargah_beslisi ++ @hicaz_beslisi ++ @hicaz_dortlusu,
      sevkefza_3:         @nikriz_beslisi ++ @hicaz_beslisi ++ @hicaz_dortlusu,
      ferahfeza:          @buselik_beslisi ++ @hicaz_dortlusu, # There should be more variations of ferahfeza
      ferahfeza_2:        @buselik_beslisi ++ @ussak_dortlusu,
      yegah:              @rast_beslisi ++ @buselik_dortlusu,
      yegah_2:            @rast_beslisi ++ @ussak_dortlusu ++ @rast_beslisi
  ]


  def interval(scale), do: @scale_intervals[scale]
  def notes(base_note, scale) do

    {seq, _acc} =
      @scale_intervals[scale]
      |> Enum.map_reduce(base_note, fn offset, acc ->

        next_note = acc + offset
        {acc, next_note}

        end)

    seq

  end






  def acc_cycle(start_note, num_notes, intervals, callback_function) do
    intervals
    # |> Enum.drop(1)
    |> Stream.cycle()
    |> Enum.take(num_notes)
    |> Enum.map_reduce(start_note, fn offset, acc ->
      ret = {offset, acc+offset};
      callback_function.(acc);
      ret end)
  end

  def generate_notes(start_note, num_notes, intervals) do

    {seq, _acc} =
      intervals
      |> Stream.cycle()
      |> Enum.take(num_notes)
      |> Enum.map_reduce(start_note, fn offset, acc ->

        next_note = acc + offset
        {acc, next_note}

        end)

    seq
  end

  def generate_notes(start_note, num_notes, intervals, callback_function) do
    intervals
    # |> Enum.drop(1)
    |> Stream.cycle()
    |> Enum.take(num_notes)
    |> Enum.map_reduce(start_note, fn offset, acc ->
      ret = {offset, acc+offset};
      callback_function.(acc);
      ret end)
  end





end
