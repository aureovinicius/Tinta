# Tinta — Estúdio Literário Markdown para macOS

**Tinta** é um aplicativo nativo para macOS escrito em **Swift (SwiftUI + AppKit)** projetado especialmente para escritores, romancistas e autores que desejam escrever, estruturar, revisar e compilar livros em Markdown.

---

## Principais Recursos para Escritores

1. **Fichário Estruturado do Livro (Binder)**
   - **Manuscrito em Atos/Partes e Capítulos**: Organize o livro por atos, reordene capítulos, acompanhe status (`Ideia`, `Rascunho`, `Em Escrita`, `Em Revisão`, `Finalizado`), aplique etiquetas de cor e defina metas de palavras por capítulo.
   - **Bíblia da História (Mundo & Elenco)**:
     - **Personagens**: Fichas completas com papel narrativo (`Protagonista`, `Antagonista`, `Deuteragonista`, `Mentor`, `Coadjuvante`), idade, arquétipo, descrição física, motivação externa, conflito interno, arco narrativo e **rastreamento automático de aparições e POV** nos capítulos.
     - **Locais & Cenários**: Fichas com região, atmosfera, detalhes sensoriais (sons, cheiros, luz, texturas), história e capítulos ambientados no local.
     - **Notas & Pesquisa**: Caderno Markdown integrado para pesquisa histórica, regras de mundo e referências.
   - **Lixeira Segura**: Capítulos excluídos vão para a Lixeira do projeto e podem ser restaurados com um clique.

2. **Editor Markdown Literário Nativo (AppKit `NSTextView`) & Modo Noturno**
   - **Modo Noturno com Um Clique (`⌃⌘N`)**: Botão dedicado de Lua/Sol na barra de ferramentas principal, no rodapé do editor e no popover de Tipografia que alterna instantaneamente toda a interface do macOS (`Dark Aqua` / `Aqua`), lembrando seu tema diurno e seu tema noturno preferidos.
   - **3 Paletas Noturnas Editoriais + 3 Diurnas**:
     - *Noturnas*: **Meia-Noite** (ardósia profundo com texto marfim), **Noturno Âmbar** (baixa luz azul com tons sépia-escuros para conforto ocular à noite) e **Obsidiana OLED** (alto contraste em preto carbono).
     - *Diurnas*: **Pólen Literário**, **Tinta Clara** e **Sépia Clássico**.
   - **Realce Sintático Editorial**: Destaque para cabeçalhos (`#`, `##`, `###`), negrito, itálico, citações (`>`), quebras de cena (`* * *`), notas ocultas de revisão (`%% ... %%`), links para a Bíblia da História (`[[Personagem]]`) e **realce sutil para linhas de diálogo literário** iniciadas por travessão (`—`).
   - **Conversão Automática de Travessão**: Digitar `-- ` converte automaticamente para o travessão literário `— `.
   - **Modo Máquina de Escrever (`⌥⌘T`)**: Mantém a linha ativa sempre centralizada verticalmente na tela.
   - **Modo Foco**: Destaca apenas a **Frase Atual** ou o **Parágrafo Atual**, suavizando o restante do texto.
   - **Modo Zen Sem Distrações (`⇧⌘F`)**: Oculta barras laterais e ferramentas para imersão total no texto.
   - **Divisão de Capítulo no Cursor (`⇧⌘D`)**: Divide um capítulo longo em dois exatamente na posição do cursor.

3. **Cinco Modos de Visualização (`⌘1` a `⌘5`)**
   - **`⌘1` Editor**: Foco total na escrita em Markdown.
   - **`⌘2` Editor + Prova Tipográfica**: Visão dividida lado a lado mostrando o Markdown à esquerda e a página diagramada com capitulares (*drop caps*) e tipografia clássica à direita.
   - **`⌘3` Quadro de Fichas (Corkboard)**: Grade visual de cartões de índice com edição rápida de sinopses, etiquetas de cor, POV, status e reordenação.
   - **`⌘4` Escaleta & Ritmo**: Tabela estrutural do livro acompanhada de um **Gráfico de Ritmo e Extensão dos Capítulos** para analisar o equilíbrio narrativo entre capítulos e atos.
   - **`⌘5` Modo Leitura do Livro**: Lê o livro inteiro diagramado com Folha de Rosto, Epígrafe, Sumário interativo e todos os capítulos em sequência.

4. **Inspetor Literário, Análise de Estilo & Instantâneos (Snapshots)**
   - **Análise Estilística em Tempo Real**: Contagem de palavras, páginas estimadas, tempo de leitura, tempo de narração em voz alta, média de palavras por frase e **proporção de diálogo (`%`)**.
   - **Detector de Eco Lexical**: Identifica as palavras mais repetidas no capítulo (ignorando preposições/artigos comuns do português) para auxiliar no refinamento estilístico.
   - **Instantâneos de Capítulo (`⇧⌘S`)**: Salve versões (*snapshots*) do capítulo antes de grandes cortes ou reescritas e restaure quando quiser.
   - **Sprint de Escrita (Pomodoro Literário 25 min)**: Cronômetro integrado na barra inferior que contabiliza quantas palavras novas foram escritas durante a sessão.

5. **Compilação e Exportação (`⇧⌘E`)**
   - **eBook EPUB 3 para Kindle / Apple Books (`.epub`)** com pacote OPF, sumário interativo (`nav.xhtml` + `toc.ncx`), capítulos XHTML, listas e tabelas formatadas para *Send to Kindle* e *Amazon KDP*.
   - **Manuscrito Markdown Único (`.md`)** com metadados YAML, folha de rosto, epígrafe e sumário.
   - **Livro Tipográfico HTML5 (`.html`)** com CSS editorial, capitulares (*drop caps*) e formatação pronta para impressão.
   - **Livro Diagramado em PDF (`.pdf`)** paginado nativamente em A4.
   - **Pasta Estruturada de Arquivos Markdown** com capítulos numerados, fichas de personagens, cenários, notas e backup JSON.

---

## Como Compilar e Executar

### 1. Gerar e abrir o pacote nativo `Tinta.app`
```bash
make open
```
*(Ou execute `./scripts/bundle_app.sh release && open Tinta.app`)*

### 2. Executar diretamente via Swift Package Manager
```bash
swift run Tinta
```

### 3. Executar a suíte de testes automatizados
```bash
swift test
```
