# ---------------------------------------------
# Analyse Wohnbevölkerung 2010 / 2022 (BFS)
# ---------------------------------------------

# Pakete laden
library(tidyverse)
library(readxl)

# ---------------------------------------------
# 1. Funktion: Ein Jahr einlesen & auf Gemeindeniveau bringen
# ---------------------------------------------
# - Liest die einzelnen Tabellenblätter ein und bereinigt die Altersstruktur
# - Extrahiert Kanton, Bezirk und Gemeinde aus der Spalte "Region"
# - Füllt Hierarchie nach unten und reduziert auf Gemeindedaten

lade_jahr <- function(jahr) {
  read_excel("wohnbevoelkerung.xlsx", sheet = as.character(jahr), skip = 1) |>
    rename(`100` = `100 und mehr`) |>
    mutate(
      Jahr = jahr,
      Kanton = if_else(str_starts(Region, "- "),
                       str_trim(str_remove(Region, "^- ")), NA_character_),
      Bezirk = if_else(str_starts(Region, ">> Bezirk "),
                       str_trim(str_remove(Region, "^>> Bezirk ")), NA_character_),
      Gemeinde = if_else(
        str_starts(Region, "......"),
        str_trim(str_replace(Region, "^.*?[0-9]{4}\\s+", "")),
        NA_character_
      )
    ) |>
    fill(Kanton, Bezirk, .direction = "down") |>
    drop_na(Gemeinde)
}

# ---------------------------------------------
# 2. Daten beider Jahre laden & kombinieren
# ---------------------------------------------
# - Vereinheitlichte Datenstrukturen aus 2010 und 2022 zusammenführen

jahre <- c(2010, 2022)
daten <- map_dfr(jahre, lade_jahr)

alter_cols <- as.character(0:100)

# ---------------------------------------------
# 3. Altersgruppen bilden
# ---------------------------------------------
# - Zusammenfügen der Altersjahre zu vier Gruppen:
#   Kinder, Minderjährige, Erwachsene <65, Erwachsene 65+

daten <- daten |>
  mutate(
    Kinder            = rowSums(across(all_of(as.character(0:12))),   na.rm = TRUE),
    Minderjaehrige    = rowSums(across(all_of(as.character(0:17))),   na.rm = TRUE),
    Erwachsene_u65    = rowSums(across(all_of(as.character(18:64))),  na.rm = TRUE),
    Erwachsene_65plus = rowSums(across(all_of(as.character(65:100))), na.rm = TRUE)
  )

# ---------------------------------------------
# 4. Statistische Kennwerte der Altersgruppen
# ---------------------------------------------
# - Altersgruppen ins Long-Format überführen
# - Mittelwert, Median und Standardabweichung berechnen (gesamt)
# - Kennwerte runden und als CSV exportieren

statistik <- daten |>
  select(Jahr, Kanton, Bezirk, Gemeinde, Kinder, Minderjaehrige, Erwachsene_u65, Erwachsene_65plus) |>
  pivot_longer(cols = Kinder:Erwachsene_65plus, names_to = "Altersgruppe", values_to = "Bevoelkerung") |>
  group_by(Altersgruppe) |>
  summarise(
    Mittelwert = mean(Bevoelkerung, na.rm = TRUE),
    Median     = median(Bevoelkerung, na.rm = TRUE),
    SD         = sd(Bevoelkerung, na.rm = TRUE),
    .groups    = "drop"
  ) |>
  mutate(across(where(is.numeric), ~ round(.x, 2)))

write_csv(statistik, "statistik_altersgruppen.csv")

# ---------------------------------------------
# 5. Durchschnittsalter nach Bezirk (ZH)
# ---------------------------------------------
# - Daten nach Altersjahr ins Long-Format
# - Altersgruppe je Alter zuordnen
# - Gewichtetes Durchschnittsalter pro Bezirk/Jahr/Gruppe berechnen
# - Differenz 2022–2010 bestimmen und exportieren

daten_long <- daten |>
  pivot_longer(cols = all_of(alter_cols), names_to  = "Alter", values_to = "Anzahl") |>
  mutate(Alter = as.numeric(Alter))

zuerich_long <- daten_long |>
  filter(Kanton == "Zürich") |>
  mutate(
    Altersgruppe = case_when(
      Alter <= 12 ~ "Kinder",
      Alter <= 17 ~ "Minderjaehrige",
      Alter <= 64 ~ "Erwachsene_u65",
      TRUE        ~ "Erwachsene_65plus"
    )
  )

durchschnitt_gruppen <- zuerich_long |>
  group_by(Bezirk, Jahr, Altersgruppe) |>
  summarise(
    Durchschnittsalter = weighted.mean(Alter, Anzahl, na.rm = TRUE),
    .groups = "drop"
  )

diff_durchschnitt <- durchschnitt_gruppen |>
  pivot_wider(names_from  = Jahr, values_from = Durchschnittsalter, names_prefix = "Jahr_") |>
  mutate(
    Differenz = Jahr_2022 - Jahr_2010,
    Jahr_2010 = round(Jahr_2010, 2),
    Jahr_2022 = round(Jahr_2022, 2),
    Differenz = round(Differenz, 2)
  )

write_csv(diff_durchschnitt, "durchschnittsalter_diff_zuerich.csv")

# ---------------------------------------------
# 6. Boxplot erstellen
# ---------------------------------------------
# - Durchschnittsalter der Minderjährigen je Gemeinde/Jahr berechnen
# - Nur Gemeinden des Kantons Zürich (ohne Stadt Zürich)
# - Boxplot der Verteilungen für 2010 und 2022 erstellen

gemeinde_minderj <- zuerich_long |>
  filter(Alter < 18) |>
  group_by(Bezirk, Gemeinde, Jahr) |>
  summarise(
    Durchschnittsalter = weighted.mean(Alter, Anzahl, na.rm = TRUE),
    .groups = "drop"
  ) |>
  filter(Gemeinde != "Zürich")

p <- ggplot(gemeinde_minderj, aes(x = factor(Jahr), y = Durchschnittsalter, fill = factor(Jahr))) +
  geom_boxplot(outlier.alpha = 0.6, outlier.size = 1.8) +
  scale_fill_manual(values = c("2010" = "#a7d0e4", "2022" = "#63b0d9")) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "none",
    plot.title = element_text(hjust = 0.5, face = "bold"),
    axis.title.x = element_text(margin = margin(t = 10)),
    axis.title.y = element_text(margin = margin(r = 10))
  ) +
  labs(
    title = "Durchschnittsalter der Minderjährigen\nGemeinden der Bezirke des Kantons Zürich (ohne Stadt Zürich)",
    x = "Jahr",
    y = "Durchschnittsalter der Minderjährigen"
  )

print(p)
ggsave("boxplot_minderjaehrige.png", plot = p, width = 8, height = 6, dpi = 300)