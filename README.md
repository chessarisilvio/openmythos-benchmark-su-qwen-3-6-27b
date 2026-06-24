# OpenMythos Benchmark su Qwen 3.6 27B

## Descrizione
Questo progetto contiene script e documentazione per eseguire benchmark del modello Qwen 3.6 27B (quantizzato Q4_K_M) sulla GPU NVIDIA Tesla P40. Il benchmark misura throughput (token/s) e latenza (ms) utilizzando `llama-bench` e un semplice script di test.

## Architettura
- **Modello**: Qwen 3.6 27B Q4_K_M (GGUF)
- **Server**: `llama-server` avviato tramite `start-llama` con preset `27b`
- **Script**: `run-benchmark-p40.sh` avvia il server, esegue `llama-bench`, misura latenza e salva risultati in `benchmark-results/`
- **Output**: JSON con throughput e latenza, log grezzi

## Installazione
1. Copia il modello GGUF nella cartella `opt/modelli-ai/qwen3.6-27b/` o imposta la variabile `MODEL_PATH`.
2. Installa le dipendenze: `start-llama`, `llama-bench`, `curl`, `jq`.
3. Assicurati che `start-llama` sia configurato con il preset `27b`.

## Uso
```bash
./run-benchmark-p40.sh
```
Lo script avvierà il server, eseguirà il benchmark e salverà i risultati in `benchmark-results/`.

## Esempi
- `benchmark-results/p40_benchmark_YYYYMMDD_HHMMSS.json`
- `benchmark-results/bench_raw_YYYYMMDD_HHMMSS.log`

## Stato
✅ Fase 1/5 – Ricerca benchmark completata
✅ Fase 2/5 – Analisi comparativa metriche completata
✅ Fase 3/5 – Script di test per P40 completato
✅ Fase 4/5 – Documentazione vault di sistema completata
✅ Fase 5/5 – Progetto completato
