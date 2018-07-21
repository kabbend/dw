
local magic = {

"Argo-Thaan, Sainte-Vengeresse, Proche, 2 poids, Il existe de nombreuses épées dans ce monde, mais il y a une seule Argo-Thaan. C’est une lame d’or, d’argent et de la lumière, vénérée comme une relique sainte par tous les ordres et toutes les religions qui croient au Bien. La toucher est une bénédiction et pour beaucoup, sa vue provoque des larmes de joie.  Dans les mains d’un paladin, c’est une arme fiable et puissante. Un paladin qui la porte augmente son dé de dégâts à d12 et a accès à toutes les actions de paladin. Qui plus est, Argo-Thaan peut nuire à toute créature du Mal, peu importe ses défenses. Aucune créature maléfique ne peut la toucher sans subir d’atroces souffrances. Dans les mains d’un non-paladin, c’est simplement une épée, plus lourde et plus encombrante que la moyenne avec le marqueur maladroit.  Argo-Thaan, bien que n’ayant pas d’intelligence propre, sera toujours attirée par une bonne cause, comme le fer par un aimant.",

"Flèches d’Achéron 1 munition, 1 poids Fabriquées dans l’obscurité par un artisan aveugle, ces flèches peuvent trouver leur cible même dans les ténèbres les plus profondes.  Un archer peut les tirer dans le noir, sûr de faire mouche les yeux bandés d’un épais tissu. Cependant, si jamais la lumière du soleil venait à toucher ces flèches, celles-ci se disperseraient comme ombre ou poussière.",

"Hache du Roi-Conquérant Proche, 1 poids Elle est faite d’acier étincelant, brillant d’une lumière dorée et est dotée du mythique pouvoir d’autorité. Lorsque vous portez la hache, vous devenez un phare d’inspiration pour tous ceux que vous commandez. Toutes les recrues à votre service ont +1 loyauté, peu importent vos qualités de chef.",

"Pointe du Sombre Portail 0 poids Ce clou ou crochet tordu, à jamais glacé, aurait été arraché, dit-on, du Sombre Portail du Royaume des Morts. Lorsqu’il est planté dans un cadavre, il disparaît et garantit que le cadavre ne sera jamais ressuscité. Nulle magie, exceptée celle de la Mort elle-même, ne peut raviver la flamme de la vie (naturelle ou non) dans ce corps.",

"Sac de transport 0 poids Un sac de transport est plus grand à l’intérieur qu’à l’extérieur et peut contenir un nombre infini d’objets sans jamais augmenter son poids.  Lorsque vous essayez de récupérer un élément dans un sac de transport, lancez 2d6+SAG. Sur un 10+, vous le trouvez immédiatement. Sur 7-9, choisissez un : (A) Vous trouvez ce que vous cherchez, mais il faut un certain temps (B) Vous obtenez un objet similaire au choix du MJ, mais ça ne prend qu’un instant Peu importe le nombre d’articles qu’il contient, un sac de transport a toujours 0 poids.",

"La Roue Ardente 2 poids Une ancienne roue en bois, cerclée d’acier, comme on en trouve sur les chariots de guerre.  Au premier abord, elle n’a rien de spécial - certains de ses rayons sont cassés et l’objet semble banal. Une détection magique ou les yeux d’un expert révèlent sa vraie nature : la Roue Ardente est un cadeau du Dieu du Feu et brûle avec son autorité.  Lorsque vous brandissez la Roue Ardente et prononcez le nom d’un dieu, lancez 2d6+CON.  Sur 7+, le dieu que vous nommez vous prête attention et vous accorde une audience. Une audience avec un dieu ne va pas sans un prix : sur un 10+, choisissez une de vos caractéristiques et réduisez-la au niveau du modificateur immédiatement inférieur (par exemple, un 14 qui octroie un bonus de +1 est ramené à 12 dont le bonus est +0). Sur un 7-9, le MJ choisit la caractéristique à réduire.  Une fois utilisée, la Roue Ardente s’enflamme et brûle d’une lumière vive. Elle ne confère aucune protection contre les flammes, ni de bonus à la natation.",

"La corne d’abondance du Capitaine Bligh 1 poids Une corne de marine en laiton, recourbée et décorée, sculptée des symboles des dieux de l’abondance. Embouchée, elle produit à la fois son et nourriture. Assez pour rassasier quiconque entend le son.",

"La Flèche de Carcosa Lancé, 3 poids Personne ne sait d’où provient cette pointe tordue de corail blanc. Ceux qui la portent trop longtemps ont l’esprit encombré de rêves bizarres et se mettent à percevoir les pensées étranges des Autres. Nul n’est à l’abri. Utilisé contre toute cible « naturelle » (humains, gobelins, hibours, etc.) la Flèche agit comme une simple lance. Sa vraie nature est de blesser ces choses que leur nature étrange protège des armes ordinaires. Utilisée ainsi, la Flèche peut blesser des adversaires invulnérables. Le porteur discernera ses ennemis dès qu’il les verra. La Flèche reconnaît les siens.",

"La Cape des Étoiles Silencieuses 1 poids Cette cape parée d’épais velours noir et constellée de petits points lumineux au revers, a la propriété d’infléchir le destin, le temps et la réalité autour d’elle pour protéger le porteur qui peut alors défier le danger avec la caractéristique qu’il préfère. Pour ce faire, l’utilisateur invoque la magie de la cape et décrit comment le manteau l’aide à « tordre les règles ». On peut ainsi dévier une boule de feu avec le CHA en la persuadant qu’on mérite de vivre ou échapper à une chute mortelle en utilisant la puissante logique de son INT pour prouver que la chute ne fera pas mal.  La cape rend tout cela possible. Elle ne peut être utilisée qu’une seule fois pour chaque caractéristique avant de perdre sa magie.",


"Piécette du Souvenir 0 poids Ce qui semble, au premier regard, être une simple monnaie de cuivre est, en réalité, une pièce enchantée. Son porteur peut, à tout moment, la troquer contre le souvenir d’un fait qui a été oublié. La pièce disparaît peu après. Cela n’a pas à être une chose oubliée par le porteur, mais elle ne peut être « connue ». L’interprétation de cette règle est laissée aux dieux. Si la pièce ne marche pas, elle laissera cependant une image dans l’esprit de quelqu’un ou de quelque chose qui se souviendra ce qui était recherché.",

"Parchemin ordinaire 1 utilisation, 0 poids Il y a un sort inscrit sur le parchemin ordinaire.  Vous devez être en mesure de le lancer ou bien celui-ci doit figurer dans la liste de sorts de votre classe. Lorsqu’il est lancé à partir d’un parchemin, un sort prend tout simplement effet.  Huile de Fléau du Diable 1 utilisation, 0 poids Cette huile sainte a été créée en quantité limitée par une secte de moines montagnards muets dont l’ordre a jadis protégé l’humanité des pouvoirs des profondeurs démoniaques. Il en reste seulement quelques pots. Appliquée à toute arme utilisée pour frapper un habitant d’un plan extérieur, l’huile annule la magie qui lie cette créature.  Dans certains cas, cela la renverra chez elle. Dans d’autres, elle annule simplement la magie qui en assure le contrôle. L’huile reste sur l’arme pendant quelques heures avant de s’évaporer.  Appliquée en cercle ou à l’encadrement d’une porte, l’huile repoussera les créatures des plans extérieurs qui ne pourront la franchir. L’huile dure une journée complète avant d’être absorbée ou de disparaître.",

"Cire de ver d’oreille 1 utilisation, 0 poids C’est une bougie jaunâtre qui ne semble jamais se consumer et dont la lumière est étrange et blême.  De même, la cire est toujours froide. Faites couler de la cire dans l’oreille d’une victime et retenez 3.  Utilisez une retenue pour poser une question à votre cible et la contraindre à vous révéler toute la vérité bien malgré elle. Ensuite, à vous de faire face aux conséquences de vos actes. ",

"L’Écho 0 poids C’est une bouteille apparemment vide. Une fois débouchée, les murmures d’un autre plan résonnent une fois et se taisent. Dans le silence, le porteur apprend en son âme la venue d’un grand danger et comment il peut l’éviter. À tout moment après avoir utilisé l’Echo, vous pouvez ignorer les résultats d’un unique lancer de dés, le vôtre ou celui d’un autre joueur et les relancer. Une fois ouvert, l’Echo est libéré et disparaît à jamais.",

"La lentille d’Epoch 1 poids Un archimage, trop vieux et faible pour quitter sa tour, conçut ce dispositif complexe et fragile de verre et d’or afin de contempler les antiquités et les reliques qu’il aimait tant. Regarder un objet à travers la lentille procure des visions sur son auteur et son origine.",

"Pierre de Longuevue 1 poids Des nuages tourbillonnants emplissent cet orbe et l’on entend souvent d’étranges murmures en sa présence. Dans les temps anciens, il faisait partie d’un réseau de pierres semblables utilisées pour communiquer et voir sur de grandes distances. Lorsque vous regardez dans la pierre, nommez un emplacement et lancez 2d6+SAG. Sur 10+, vous avez une vision claire de l’emplacement et pouvez la conserver aussi longtemps que vous vous concentrez sur l’orbe.  Sur un 7-9, vous avez toujours la vision, mais vous attirez l’attention de quelque chose d’autre (un ange, un démon, ou le possesseur d’une autre pierre de Longuevue) qui utilise la pierre pour vous observer également.",

"Le Codex du Fiasco 0 poids Cet ouvrage épais, que l’on dit écrit par un prince démon pétri d’humour noir avec le sang de pauvres imbéciles et d’exploiteurs crapuleux, regroupe les contes et histoires de ceux dont l’ambition a submergé la raison. La lecture de ce tome enseigne la valeur de la lucidité, mais laisse subsister un sentiment d’effroi. Quand vous lisez le Codex du Fiasco, lancez 2d6+SAG. Sur 10+, posez deux des questions ci-dessous. Sur 7-9, posez-en une.  (A) Qelle est ma plus grande opportunité en ce moment ? (B)  Qui puis-je trahir pour obtenir un avantage ?  (C)  A quel allié ne devrais-je pas faire confiance ?  Le Codex ne donne ses réponses qu’une seule fois à chaque lecteur et prend 2 à 3 heures à lire.",

"Flacon de Souffle 0 poids Une chose simple mais utile lorsque vous avez besoin d’une bouffée d’air frais. Le flacon semble vide, mais ne peut pas être rempli. Tout ce qui y est ajouté déborde simplement car le flacon est éternellement plein d’air. S’il est placé sous l’eau, il produira des bulles sans arrêt. On peut respirer normalement lorsqu’on le porte à la bouche. La fumée n’est plus un souci, par exemple. Je suis sûr que vous trouverez toutes sortes d’utilisations inhabituelles à cet objet. ",

" La folie déployée, Les ailes de cire, Une énorme erreur 1 poids Qui n’a jamais voulu grimper en flèche dans le ciel bleu ? Ces grandes ailes magiques ont été créées pour tenter d’exaucer les voeux des terriens.  Connues sous plusieurs noms et fabriquées par autant de mages, elles prennent habituellement la forme d’ailes d’oiseaux auxquels on voue de l’affection. On les fixe à l’aide d’un harnais ou, dans les cas extrêmes, par une intervention chirurgicale.  Lorsque vous vous envolez avec ces ailes magiques, lancez 2d6+DEX. Sur 10+, vous maîtrisez votre vol et pouvez rester en l’air aussi longtemps que vous le souhaitez. Sur un 7-9, vous vous envolez, mais votre vol est soit court, soit erratique et imprévisible, au choix. Sur 6-, vous vous envolez, mais le MJ vous racontera la chute et tout ce qui la précède.",

"La baguette inamovible 0 poids C’est une tige métallique étrange dotée d’un bouton. Appuyez sur le bouton et la tige tient toute seule. Elle se fige sur place dans les airs, à la verticale ou à l’horizontale et ne peut être déplacée.  Tirez-la, poussez-la, essayez aussi fort que vous le souhaitez, la baguette est inamovible. On peut peut-être la détruire, ou pas. Appuyez de nouveau sur le bouton pour la libérer et l’emmener avec vous. Un truc aussi buté peut s’avérer utile.",

"Le livre infini 1 poids Ce livre contient un nombre infini de pages dans un espace fini. Sans limite de pages, tout ce qui a jamais été, est, ou sera, est contenu quelque part dans le livre. Heureusement l’index est bien fait.  Lorsque vous étalez votre science tout en consultant le livre vous gagnez un résultat supplémentaire : Sur un 12+, le MJ va donner une solution à un problème ou une situation dans laquelle vous vous trouvez.",

"Inspectrices 0 poids Ces lunettes sont faites de verres grossièrement taillés dans une monture en bois. Bien que tordues et presque cassées, elles permettent au porteur de voir bien plus que ses simples yeux ne l’autorisent.  Lorsque vous discernez la réalité avec ces puissants lorgnons, vous parvenez à tordre un peu les règles.  Sur un résultat de 10+, posez trois questions de votre choix. Elles n’ont pas à figurer sur la liste. Le MJ vous dira ce que vous voulez savoir dès lors que cette vision peut vous donner des réponses.",

"La manoeuvre de Ku’meh 1 poids Grand ouvrage de cuir poli par les mains de centaines de généraux, ce livre est souvent transmis de guerrier à guerrier, de père à fils tout au long des batailles qui ont divisé ce monde par le passé. Toute personne qui le lit peut, après l’avoir achevé pour la première fois, lancer 2d6+INT. Sur un 10+, retenez 3. Sur 7-9, retenez 1. Vous pouvez dépenser une retenue pour conseiller un compagnon sur une question d’une importance stratégique ou tactique. Ce conseil vous permet, à tout moment, indépendamment de la distance, de l’aider sur un jet. Sur un échec, le MJ peut retenir 1 et le dépenser pour appliquer un malus de -2 à l’un de vos jets de dés ou à celui du pauvre gars qui aura prêté une oreille à vos conseils.",

"Memento Mori 0 poids Constitué d’une seule mèche de cheveux roux liée par un ruban noir préservé des ravages du temps, le Memento Mori est porteur d’un sombre enchantement. Cet objet contient les souvenirs et les émotions d’une jeune fille qui a négocié tant de fois avec la Mort devant le Sombre Portail qu’à la fin elles sont tombées amoureuses.  Elle a alors quitté le monde pour la rejoindre pendant quelques temps. Son souvenir protège le porteur. S’il se trouve lui-même devant le Sombre Portail, le Memento peut être échangé contre un résultat automatique de 10+ sur l’action dernier soupir.",

"Le Bouclier Aimant +1 armure, 1 poids Quel est l’abruti qui a fabriqué ça ? Les boucliers sont destinés à repousser le métal, pas à l’attirer !  Arborant un lion rampant, le Bouclier Aimant a le pouvoir d’attirer les lames et les flèches à lui. Lorsque vous défendez contre un ennemi qui utilise une arme en métal, vous pouvez dépenser une retenue pour le désarmer. Parfois, une poignée de petite monnaie s’y colle aussi.",

"Carte de la Dernière Patrouille 0 poids Un ancien ordre de braves éclaireurs patrouillait autrefois ces terres, protégeant les villages et avertissant les rois et reines d’un danger en approche. Ils sont partis depuis longtemps, mais leur héritage demeure. Cette carte, une fois marquée avec le sang d’un groupe de personnes, saura toujours montrer leur emplacement tant qu’ils restent dans les limites de la carte.",

"La Tête de Ned 1 poids C’est un vieux crâne, très mal en point, dont il manque la mâchoire. Le crâne se souvient de la folie de son ancien propriétaire, un homme avec plus d’honneur que de bon sens. Une fois par nuit, le propriétaire du crâne peut demander « Qui m’en veut ? » et le crâne lâchera un nom d’une triste voix solitaire. Si le propriétaire du crâne est tué, ce dernier disparaît curieusement. Personne ne sait où il réapparaîtra la prochaine fois.",

"Clé du Noctambule 0 poids Cette clé déverrouille une porte pour vous, à la condition que vous ne soyez pas le bienvenu là où vous souhaitez aller. Tant que vous ne faites rien qui pourrait alerter quelqu’un de votre présence (en restant inaudible, invisible et insaisissable) et que vous n’emportez rien de plus que vos souvenirs avec vous, la magie de la clé rendra votre intrusion absolument indécelable. C’est comme si vous n’aviez jamais été là.",

"Herbes sacrées 0 poids Les herbes sacrées, cueillies et préparées par un ordre de moines-magiciens disparus, peuvent être trouvées par lots de deux ou trois utilisations.  Conservées au sec, elle durent indéfiniment. Qu’elles soit bourrées dans une pipe ou brûlées dans un encensoir, l’épaisse fumée bleue de ces herbes vous accordera d’étranges visions de contrées ou de temps lointains. Si vous concentrez votre volonté sur une personne, un lieu ou une chose, les herbes vont répondront. Lancez 2d6+SAG.  Sur 10+, la vision est claire et utile et vous apporte des informations fiables. Sur 7-9, la vision est bien celle de la chose recherchée, mais elle reste obscure, chargée de métaphores et, quoi qu’il en soit, difficile à comprendre. Sur un échec, le MJ vous demandera, « Que craignez-vous le plus ? » Vous devez répondre honnêtement, bien sûr.",

"Le Canard de Sartar 0 poids Un canard bizarre, sculpté dans le bois. Qui fabriquerait une chose si curieuse ? Lorsque vous le portez, vous devenez très doué pour raconter des histoires. Quelle que soit la langue, tout le monde est en mesure de comprendre, du moins le sens à défaut des mots. ",

"Larmes d’Anne-Lise 0 poids Les larmes d’Anne-Lise sont des pierres taillées d’un rouge trouble et de la taille d’un ongle. On les trouve toujours par paires. Lorsque chacune est ingérée par deux personnes différentes, cellesci sont liées. Lorsque l’une ressent une émotion forte (en particulier de la tristesse, la perte, la peur ou le désir), l’autre la ressent aussi. Les effets durent jusqu’à ce que l’une verse le sang de l’autre.",

"Chambre de Téléportation Lent James Neufdoigts, mage génial et excentrique, a créé ces artefacts magiques de la taille d’une pièce. Il s’agit de chambres de pierre, gravées de runes et de gribouillages variés brillant d’une lumière bleu pâle.  Lorsque vous entrez et dites à haute voix le nom d’un emplacement, lancez 2d6+INT. Sur un 10+, vous arrivez exactement où vous en avez l’intention.  Sur un 7-9, le MJ choisit un endroit sûr à proximité.  Sur un échec, vous vous retrouvez quelque part.  Peut-être à proximité, mais certainement pas en sécurité. Des choses étranges arrivent parfois à ceux qui courbent le temps et l’espace avec ces dispositifs.",

"Armure de Timunn 1 armure, 1 poids Cette armure discrète, qui se fond avec les vêtements, apparaît différemment à chacun. Le porteur semble toujours au dernier cri de la mode pour tous ceux qui le regardent.",

"Suif de Vérité de Titus 0 poids C’est une bougie de suif aux couleurs d’ivoire et de cuivre avec une mèche d’argent tressé.  Lorsqu’elle est allumée, ceux qu’elle éclaire sont incapables de mentir. Ils peuvent garder le silence ou simuler, mais lorsqu’on leur pose une question directe, ils ne peuvent que dire la vérité.",

"Corde Astucieuse 1 poids Une corde qui obéit et qui accomplit aussi des tours, comme le ferait un serpent intelligent et obéissant. Dites-lui « Enroule-toi » ou « Relâche toi » ou « Viens ici, corde » et elle le fera.",

"Le Miroir d’Argent 0 poids Fabriqué par des orfèvres nains, ce miroir à main métallique est profondément marqué de runes de puissance et de rajeunissement. Destiné à remplacer des membres blessés ou détruits dans des accidents de mines, le Miroir d’Argent se fixe à une blessure, récente ou ancienne. Dur et résistant, il peut être utilisé comme une arme (proche) et contient suffisamment d’argent pur pour nuire aux créatures que cela affecte.",

"Gantelets de Vellius 1 poids Nommés d’après Vellius le Maladroit, Vellius Deux- Mains-Gauches, Vellius l’Empoté, ces gants de tissu simple vous empêchent de lâcher un objet par mégarde. Vous ne pouvez pas être désarmé ni tomber d’une corde ou d’une échelle, par exemple.  Cet objet peut s’avérer particulièrement désagréable si vous agrippez quelque chose de solide alors que quelque chose tire fort sur vos jambes.",

"Glaive d’Intrusion Allonge, 2 poids Cette lame légendaire, que l’on dit avoir été envoyée dans le passé en prévision d’un sombre futur, est forgée d’un étrange acier vert.  La lame frappe l’esprit autant que le corps de ceux qu’elle blesse. Lorsque vous taillez en pièces, sur un 10+ vous gagnez une option supplémentaire : vous pouvez infliger vos dégâts normaux, laisser votre adversaire riposter, et lui insuffler l’émotion de votre choix (peut-être la peur, le respect, ou la confiance).",

"Epée Vorpale Proche, 3 perforant, 2 poids De taille, d’estoc et tout le toutim. Plus tranchante que tout, cette lame d’apparence simple est vouée à séparer une chose de l’autre, le membre d’un corps ou les gens de leur vie. Quand vous infligez des dégâts avec l’Epée Vorpale, votre ennemi doit choisir quelque chose (un objet, un avantage, un membre) et le perdre, définitivement.",

}

return magic

