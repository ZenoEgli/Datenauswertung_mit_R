# Datenauswertung_mit_R


## Autor

Zeno Egli (eglizen1)


## Datum

12.12.2025


##  Folgende Dokumente sind in dem Git-Rebosotory enthalten

Excel Testat

    wohnbevoelkerung.xlsx
        
    datenauswertung_zeno.r
        
    Ouput
        statistik_altersgruppen.csv
        durchschnittsalter_diff_zuerich.csv
        boxplot_minderjaehrige.png
    
    LICENSE
    
    README.md


## Inhalt

Abgabe für das Modul Daten & Information HS25 AD25

Analyse der ständigen Wohnbevökerung der Schweiz basierend auf den Daten des Bundesamts für Statistik (BFS) für die Jahre 2010 und 2022.
Die Auswertung erfolgt mit R und tidyverse-Bibliotheken.


## Datenbasis

Quelle: Bundesamt für Statistik (BFS)
https://www.bfs.admin.ch/bfs/de/home/statistiken/bevoelkerung/stand-entwicklung/raeumliche-verteilung.assetdetail.26565293.html

Format: Excel-Datei


## Ergebnisse

Das Skript erzeugt folgende Ausgabedateien:

statistik_altersgruppen.csv
    Statistische Kennwerte (Mittelwert, Median, Standardabweichung) je Altersgruppe

durchschnittsalter_diff_zuerich.csv
    Durchschnittsalter der Altersgruppen je Bezirk im Kanton Zürich sowie die Differenz zwischen 2010 und 2022

boxplot_minderjaehrige.png
    Boxplot zur Verteilung des Durchschnittsalters der Minderjährigen in Zürcher Gemeinden


## Technische Voraussetzungen

R
Pakete:
    tidyverse
    readxl