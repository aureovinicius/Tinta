import Foundation

public enum SampleBookFactory {
    public static func makeSampleBook() -> BookProject {
        let part1 = BookPart(
            title: "Ato I — A Maré Cinzenta",
            subtitle: "O retorno à ilha e o caderno submerso",
            synopsis: "Helena retorna à Ilha de São Bento após a morte do avô cartógrafo e descobre que o farol guarda mapas de costas que não deveriam existir.",
            order: 0
        )

        let part2 = BookPart(
            title: "Ato II — O Atlas das Correntes",
            subtitle: "As cartas cifradas e a vigília de inverno",
            synopsis: "A decifração das anotações em nanquim revela a rota da expedição desaparecida em 1968.",
            order: 1
        )

        let part3 = BookPart(
            title: "Ato III — O Horizonte Aberto",
            subtitle: "A última lâmpada de Fresnel",
            synopsis: "Confronto com o passado da família durante a maior ressaca do Atlântico Sul.",
            order: 2
        )

        let helena = CharacterProfile(
            name: "Helena Viana",
            role: .protagonist,
            age: "34 anos",
            archetype: "A Arquivista Relutante",
            summary: "Restauradora de livros raros e mapas náuticos que fugiu do litoral há doze anos.",
            physicalDescription: "Olhos castanho-escuros, dedos sempre marcados por resquícios de tinta ferrogálica, sobretudo de lã azul-marinho.",
            motivation: "Descobrir o que realmente aconteceu com seu avô Teodoro e com o navio *Astrolábio*.",
            internalConflict: "Medo de herdar a obsessão solitária que consumiu três gerações de sua família.",
            arcNotes: "Passa da negação e desejo de vender o farol rapidamente para assumir a memória e a autoria do grande atlas incompleto."
        )

        let teodoro = CharacterProfile(
            name: "Teodoro Viana",
            role: .mentor,
            age: "81 anos (em memória)",
            archetype: "O Guardião do Limiar",
            summary: "Último faroleiro e cartógrafo autodidata da Ilha de São Bento.",
            physicalDescription: "Barba branca aparada, relógio de bolso de latão oxidado pelo salitre, voz grave e pausada.",
            motivation: "Deixar para Helena as pistas necessárias sem entregá-las a colecionadores oportunistas.",
            internalConflict: "Carregou por cinquenta anos o segredo do naufrágio na Baía das Âncoras.",
            arcNotes: "Presente através de seus cadernos em Markdown e cartas deixadas entre as páginas dos livros."
        )

        let mateus = CharacterProfile(
            name: "Mateus Cordeiro",
            role: .deuteragonist,
            age: "39 anos",
            archetype: "O Navegador Cético",
            summary: "Capitão da embarcação de correio marítimo que abastece a ilha uma vez por semana.",
            physicalDescription: "Cicatriz fina no supercílio esquerdo, camisa de flanela surrada, conhece cada recife da costa.",
            motivation: "Proteger a comunidade pesqueira da especulação imobiliária sobre o promontório.",
            internalConflict: "Desconfia de quem foi embora da ilha, mas reconhece em Helena a única capaz de ler o espólio de Teodoro.",
            arcNotes: "Torna-se o principal aliado de Helena na travessia até o arquipélago externo."
        )

        let farol = LocationProfile(
            name: "Farol de São Bento",
            region: "Promontório Norte da Ilha",
            atmosphere: "Melancólica, silenciosa, pontuada pelo giro rítmico da lente de Fresnel e pelo vento sul.",
            sensoryDetails: "Cheiro de parafina antiga, maresia, papel úmido, madeira de cedro e chá de hortelã-pimenta.",
            description: "Torre octogonal de pedra basáltica erguida em 1894, com uma biblioteca circular no terceiro patamar.",
            notes: "A sala da lanterna possui uma acústica peculiar que amplifica o som das ondas quebrando sessenta metros abaixo."
        )

        let oficina = LocationProfile(
            name: "Oficina de Encadernação & Cartografia",
            region: "Anexo Leste do Farol",
            atmosphere: "Íntima, repleta de instrumentos de latão, prensas de madeira e vidros de pigmento.",
            sensoryDetails: "Luz âmbar das luminárias baixas, cheiro de cola de amido, couro antigo e óleo de linhaça.",
            description: "Espaço onde Teodoro desenhava cartas náuticas e restaurava diários de bordo resgatados do mar.",
            notes: "Sob a tábua solta junto à prensa principal fica a caixa de folha-de-flandres com as cartas de 1968."
        )

        let chap1Content = """
        # O Cheiro de Sal e Nanquim

        O barco de correio encostou no píer de pedra às cinco da tarde, quando a neblina já descia sobre o promontório como um véu de lã molhada. [[Helena Viana]] segurou a alça da maleta de couro com mais força antes de pisar na prancha. Doze anos não haviam mudado o som que o Atlântico fazia ao bater nas estacas de maçaranduba.

        — Se você esperar a maré baixar, não sobe a trilha com luz do dia — avisou [[Mateus Cordeiro]], sem tirar o cachimbo apagado do canto da boca. — O vento virou para o quadrante sul há meia hora.

        — Eu ainda conheço o caminho no escuro, Mateus.

        — Conhecia — corrigiu ele, amarrando o cabo de proa num cabeço de ferro coberto de cracas. — As chuvas de agosto levaram metade da escadaria velha. Vá pelo bosque de casuarinas.

        * * *

        No alto da colina, o [[Farol de São Bento]] parecia menor do que nas lembranças da infância, mas mais obstinado. A porta de cedro cedeu no segundo giro da chave de latão.

        > "Todo livro é uma embarcação que alguém lançou ao escuro esperando que outra costa a recebesse."
        > — Caderno III de [[Teodoro Viana]]

        Sobre a mesa circular da biblioteca, exatamente sob o feixe pálido da claraboia, repousava um caderno encadernado em linho cru. Ao lado dele, um tinteiro de vidro âmbar ainda aberto e uma tira de papel com três palavras sublinhadas duas vezes:

        **Não venda antes de ler a carta de novembro.**

        Helena puxou a cadeira de palhinha. O silêncio da torre não era vazio; era denso, habitado pelo tique-taque do mecanismo de relojoaria que, mesmo desligado há uma semana, parecia pulsar na memória das paredes.
        """

        let chap2Content = """
        # A Biblioteca Circular

        Durante a madrugada, a chuva começou a tamborilar nas vidraças curvas da lanterna. [[Helena Viana]] acendeu o lampião de querosene da [[Oficina de Encadernação & Cartografia]] e espalhou os sete cadernos numerados em algarismos romanos sobre a bancada de pinho.

        Cada volume correspondia a uma década, mas o **Volume IV (1965–1974)** tinha dezenas de folhas coladas umas às outras com cera de abelha.

        — Por que esconder páginas num diário que ninguém mais lia? — murmurou ela para a sala vazia.

        Com uma espátula de osso aquecida na chama baixa da lamparina, Helena começou a separar a primeira folha selada. O papel fibra de algodão revelou um mapa traçado em duas cores: nanquim preto para a costa oficial da capitania e tinta sépia para uma linha pontilhada que avançava três milhas além dos Rochedos das Garças.

        * * *

        ### Notas na Margem do Mapa

        Na borda inferior esquerda, a caligrafia inconfundível de [[Teodoro Viana]] registrava:

        1. *Primeira sondagem ao largo da Restinga Branca: 14 braças.*
        2. *Luz avistada a leste onde nenhuma carta registra farol ou boia luminosa.*
        3. *Promessa feita ao comandante do Astrolábio na noite de 19 de novembro.*

        Quando o dia clareou, batidas firmes soaram na porta da oficina. Era [[Mateus Cordeiro]], trazendo um cesto com pão fresco, café em pó e um envelope lacrado que o tabelião da vila mandara entregar antes do meio-dia.
        """

        let chap3Content = """
        # O Mapa das Três Marés

        — O advogado da construtora veio na lancha das oito — disse [[Mateus Cordeiro]], apoiando o cesto junto ao fogão a lenha. — Perguntou se você já tinha assinado a escritura do promontório.

        [[Helena Viana]] não tirou os olhos da lupa de bronze.

        — Diga a ele que o inventário dos livros vai levar pelo menos um mês.

        — Um mês? — Mateus arqueou a sobrancelha, aproximando-se da bancada iluminada. Quando viu a carta náutica de 1968 aberta sob os pesos de chumbo, sua expressão mudou. — Onde você encontrou isso?

        — Dentro do quarto caderno do meu avô. Você conhece essa enseada marcada em vermelho?

        Mateus ficou em silêncio por vários segundos. Lá fora, uma gaivota riscou o céu cor de estanho.

        — Meu pai falava desse canal quando voltava da pesca de inverno. Chamavam de *Garganta do Vidro*. Só abre na maré de sizígia de novembro, quando o banco de areia recua.
        """

        let chap1 = ChapterItem(
            partId: part1.id,
            order: 0,
            title: "O Cheiro de Sal e Nanquim",
            subtitle: "Chegada ao promontório",
            synopsis: "Helena desembarca na Ilha de São Bento, reencontra Mateus no píer e sobe ao farol onde encontra o caderno aberto deixado pelo avô.",
            notes: "Reforçar os detalhes sensoriais da maresia e da ferrugem na fechadura. Manter o diálogo inicial enxuto.",
            content: chap1Content,
            status: .final,
            colorLabel: .emerald,
            povCharacterId: helena.id,
            locationId: farol.id,
            targetWordCount: 300,
            tags: ["abertura", "chegada", "mistério"],
            snapshots: [
                ChapterSnapshot(
                    label: "Primeiro rascunho da chegada",
                    createdAt: Date().addingTimeInterval(-86400 * 3),
                    content: "# O Cheiro de Sal\n\nHelena chegou ao píer sob neblina espessa e subiu a colina até o farol do avô.",
                    wordCount: 19
                )
            ]
        )

        let chap2 = ChapterItem(
            partId: part1.id,
            order: 1,
            title: "A Biblioteca Circular",
            subtitle: "O quarto caderno selado",
            synopsis: "Na oficina de encadernação, Helena abre as folhas seladas com cera de abelha no Volume IV e descobre uma carta náutica clandestina.",
            notes: "Verificar terminologia de restauração de papel (espátula de osso, fibra de algodão, tinta ferrogálica).",
            content: chap2Content,
            status: .revision,
            colorLabel: .amber,
            povCharacterId: helena.id,
            locationId: oficina.id,
            targetWordCount: 350,
            tags: ["descoberta", "cartografia", "noite"]
        )

        let chap3 = ChapterItem(
            partId: part2.id,
            order: 2,
            title: "O Mapa das Três Marés",
            subtitle: "A Garganta do Vidro",
            synopsis: "Mateus reconhece o canal secreto desenhado por Teodoro e revela que a passagem só se abre na maré de sizígia de novembro.",
            notes: "Preparar o gancho para a primeira saída de barco no Capítulo 4.",
            content: chap3Content,
            status: .inProgress,
            colorLabel: .sapphire,
            povCharacterId: helena.id,
            locationId: oficina.id,
            targetWordCount: 400,
            tags: ["diálogo", "revelação", "maré"]
        )

        let chap4 = ChapterItem(
            partId: part2.id,
            order: 3,
            title: "Vigília na Lanterna",
            subtitle: "O código de lampejos",
            synopsis: "Helena descobre que as anotações numéricas do avô correspondem aos intervalos de ocultação da lente de Fresnel.",
            notes: "Cena noturna no topo da torre.",
            content: """
            # Vigília na Lanterna

            Subir os cento e quarenta degraus em espiral com o caderno debaixo do braço exigiu fôlego. No topo do [[Farol de São Bento]], os prismas concêntricos da grande lente de cristal refletiam a lua minguante em dezenas de lâminas prateadas.

            %% Lembrar de descrever o peso do contrapeso de bronze no poço central da escada %%

            — Três curtos, um longo, pausa de sete segundos — leu [[Helena Viana]] em voz alta, passando o indicador pelas colunas de números.
            """,
            status: .draft,
            colorLabel: .amethyst,
            povCharacterId: helena.id,
            locationId: farol.id,
            targetWordCount: 450,
            tags: ["lente", "código", "noturno"]
        )

        let chap5 = ChapterItem(
            partId: part3.id,
            order: 4,
            title: "A Maré de Sizígia",
            subtitle: "Travessia até a Restinga Branca",
            synopsis: "Clímax da travessia marítima antes da tempestade fechar o canal.",
            notes: "Estruturar em três movimentos rápidos alternando a navegação e a leitura do último relato.",
            content: """
            # A Maré de Sizígia

            O mar recuara mais do que qualquer morador vivo da vila jamais vira. Ao longe, onde sempre houve apenas espuma branca e arrebentação, aflorava o dorso escuro das pedras submersas.
            """,
            status: .idea,
            colorLabel: .crimson,
            povCharacterId: mateus.id,
            locationId: farol.id,
            targetWordCount: 500,
            tags: ["clímax", "oceano"]
        )

        let note1 = ResearchNote(
            title: "Lentes de Fresnel e Faróis Brasileiros do Século XIX",
            category: "Pesquisa Histórica",
            content: """
            # Lentes de Fresnel

            Inventadas pelo físico francês **Augustin-Jean Fresnel** na década de 1820, as lentes escalonadas permitiram concentrar a luz de uma simples lâmpada a óleo em um feixe visível a mais de 20 milhas náuticas.

            - **1ª Ordem**: ~2,59 m de altura, distância focal de 920 mm.
            - **Mecanismo de Rotação**: Movido por um sistema de relojoaria com pesos que desciam pelo tubo central da torre, precisando de corda manual a cada 4 horas durante a noite.
            - **Combustível histórico**: Óleo de baleia -> óleo de colza -> querosene incandescente -> eletrificação.
            """,
            tags: ["farol", "história", "óptica"]
        )

        let note2 = ResearchNote(
            title: "Restauração de Papel e Tinta Ferrogálica",
            category: "Ofício & Vocabulário",
            content: """
            # Glossário de Encadernação e Restauro

            - **Espátula de osso (Dobradeira)**: Ferramenta lisa usada para vincar papel e separar folhas delicadas sem cortar as fibras.
            - **Tinta ferrogálica**: Feita com sais de ferro e ácido tânico de galhas de carvalho; escurece com o tempo e pode oxidar o papel se houver umidade salina.
            - **Costura francesa**: Técnica tradicional que une os cadernos (*signatures*) de um livro sem necessidade de suporte rígido no dorso.
            """,
            tags: ["vocabulário", "livros", "restauro"]
        )

        let todayKey = BookStore.dateString(for: Date())

        return BookProject(
            title: "As Cartas do Farol de Vidro",
            subtitle: "Romance em três marés",
            author: "Clara Vasconcelos",
            genre: "Ficção Literária & Mistério Marítimo",
            epigraph: "Nenhum mapa termina na borda do papel; ele apenas espera quem tenha coragem de dobrar a página.",
            epigraphAuthor: "Teodoro Viana, Caderno III",
            synopsis: "Ao herdar um farol desativado e uma oficina de encadernação em uma ilha do Atlântico Sul, uma restauradora de livros descobre cartas náuticas secretas escondidas dentro de diários costurados pelo avô.",
            targetWordCount: 2000,
            dailyWordGoal: 500,
            parts: [part1, part2, part3],
            chapters: [chap1, chap2, chap3, chap4, chap5],
            characters: [helena, teodoro, mateus],
            locations: [farol, oficina],
            researchNotes: [note1, note2],
            writingLog: [
                DailyWritingEntry(dateString: todayKey, wordsWritten: 420, minutesActive: 35)
            ]
        )
    }
}
