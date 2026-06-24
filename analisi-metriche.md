# Analisi comparativa metriche benchmark OpenMythos Qwen 3.6 27B

## Fonti dei dati
- **GitHub (ajul8866/Mytos_qwen)** – accuratezza e throughput.
- **aiindigo.com** – latenza e throughput.
- **dredyson.com (deployment)** – latenza e precisione.
- **aimadetools.com** – SWE‑bench.
- **dredyson.com (tool‑calling)** – accuratezza task strutturati.

## Metriche chiave estratte
| Fonte | Accuratezza | Precisione | Latenza (ms) | Throughput (QPS) | SWE‑bench |
|-------|-------------|------------|--------------|------------------|-----------|
| GitHub | 78 % | – | – | 1200 | – |
| aiindigo.com | – | – | 35 | 1100 | – |
| dredyson.com (deployment) | – | 79 % | 30 | – | – |
| aimadetools.com | – | – | – | – | 77,2 % |
| dredyson.com (tool‑calling) | 81 % | – | – | – | – |

## Differenze osservate
1. **Latenza**: le fonti più recenti (dredyson.com) riportano latenza leggermente più bassa (30 ms) rispetto a aiindigo.com (35 ms). Possibile causa: differente hardware di test (GPU, CPU) o versione del modello.
2. **Throughput**: GitHub indica 1200 QPS, leggermente superiore a aiindigo.com (1100 QPS). Potrebbe derivare da configurazioni di batch size o dalla presenza di caching.
3. **Precisione/accuratezza**: i valori variano dal 78 % (GitHub) al 81 % (tool‑calling). La differenza può essere dovuta a metriche diverse (accuracy vs precision) e a dataset di test differenti.
4. **SWE‑bench**: unico valore disponibile è 77,2 % su aimadetools.com. Non è possibile confrontarlo direttamente con le altre metriche.

## Possibili fonti di discrepanza
- **Dataset di test**: ogni fonte utilizza set di domande/compiti diversi.
- **Versione del modello**: potrebbero esserci piccole differenze di checkpoint o patch.
- **Configurazione di inferenza**: batch size, temperatura, top‑k, ecc.
- **Hardware**: GPU (P40 vs RTX 3050), CPU, rete.
- **Metriche**: accuratezza vs precisione vs throughput.

## Raccomandazioni per la calibrazione P40 (sm_61)
1. **Riprodurre i test**: eseguire benchmark con lo stesso set di domande usato da GitHub e aiindigo.com su P40.
2. **Verificare batch size**: aumentare o diminuire per ottimizzare throughput senza sacrificare precisione.
3. **Monitorare latenza**: utilizzare strumenti di profiling (e.g., nvprof) per individuare colli di bottiglia.
4. **Confronto con altre GPU**: eseguire benchmark su RTX 3050 per valutare differenze di performance.
5. **Documentare risultati**: salvare output in file JSON/CSV per analisi successive.

---

**Nota**: i valori riportati sono estratti da fonti pubbliche e possono variare in base all’ambiente di esecuzione. Per una valutazione più accurata, è consigliato eseguire benchmark controllati con configurazioni identiche.
