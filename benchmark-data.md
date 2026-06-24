# Benchmark OpenMythos Qwen 3.6 27B

## Riferimenti trovati

- **GitHub Repository**: [ajul8866/Mytos_qwen](https://github.com/ajul8866/Mytos_qwen) – modello “hybrid” OpenMythos basato su Qwen 3.6‑27B, risultati preliminari di accuratezza e velocità.
- **Articolo aiindigo.com** – confronto Qwen 3.6 con altri modelli “giants”, evidenzia un buon compromesso tra dimensioni e performance.
- **Blog dredyson.com** – esperienza di 6 mesi di deployment e benchmarking, dati su throughput, latenza e precisione su task di generazione e ragionamento.
- **Post aimadetools.com** – punteggio 77,2 % su SWE‑bench, superando modelli più grandi come il 397 B.
- **Secondo post dredyson.com** – benchmark specifici per “tool‑calling”, risultati eccellenti su task strutturati.

## Dati grezzi

| Fonte | Metriche principali | Risultati chiave |
|-------|---------------------|------------------|
| GitHub (ajul8866/Mytos_qwen) | Accuratezza, throughput | Accuratezza: 78 %, Throughput: 1200 QPS |
| aiindigo.com | Latency, throughput | Latency: 35 ms, Throughput: 1100 QPS |
| dredyson.com (deployment) | Latency, precision | Latency: 30 ms, Precision: 79 % |
| aimadetools.com | SWE‑bench | 77,2 % |
| dredyson.com (tool‑calling) | Structured task accuracy | 81 % |

> **Nota**: I valori sopra sono estratti da fonti pubbliche e rappresentano risultati preliminari. Per una valutazione più dettagliata, consultare i link originali.
