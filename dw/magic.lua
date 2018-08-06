
local magic = {

"Caul of the seventh son A leathery piece of dried flesh stretched over a triangle of spiked metal, tattooed with strange symbols and smelling of spice.  Move: When the name of an enemy is whispered to the caul Roll+Int 10+ Choose 2 7-9 Choose 1\n Learn the enemy's weakness. Take +1 ongoing to hack and slash.\n Learn one of the enemies secrets.\n The caul doesn't whisper your location to your enemy.\n 6- The caul whispers to the enemy and tells of your intentions.",

"The lamentful whetstone A small block of bluish stone carved with the faces of the slain. Move: When you use the whetstone to sharpen your blade on waking it gains +1 piercing for the day but whenever you strike a foe, the blade will loudly ring with the wailing cries and lamentations of those who have fallen to its sharpness.",

"Avarice coin A small and very shiny coin. Move: When the coin is placed on the floor in front of an unsuspecting being who values such things, they will notice it and, if able to safely, will pick it up. However, someone who places it down will struggle to leave it behind for any period of time."  ,

"Ash twig A branch from an ash tree, strong as steel and very cold. Move: When used to draw occult symbols in the embers of last nights fire it will grow warm when pointed in the direction the wielder should travel that day. Take +1 forward to the next trailblazing roll.",

"Grimdoll A small crudely crafted rag doll with unsettling looks.\nMove: When you sleep with the Grimdoll under your pillow Roll+Wis 10+ You have a dream in which you see a Grim portent that may come to pass.\n 7-9 You have a troubling and confusing dream in which you see a Grim portent that may come to pass. Become Confused until the Grim portent comes to pass or is averted.\n 6- You have a terrifying dream in which the thing that the Grimdoll is an effigy of promises to visit you soon. And it will.",

"Mirrorfate shield A round mirrored shield. Provides +1 armour as a normal shield.\n Move: When you show a creature its image in the shield roll.\n 10+ The creature sees its own death reflected. If that causes it fear, take +1 ongoing against the creature. The mirror becomes tarnished.\n 7-9 The creature sees a glimpse of a possible death reflected. If that causes it fear, take +1 forward against the creature. The mirror becomes tarnished.\n 6- The mirror becomes tarnished.\n A tarnished Mirrorfate shield does not reflect. To clean the mirror it must be rubbed clean with the blood of a vanquished enemy for many hours.",

"Thrice blessed bindings A long length of deep blue leather. When wrapped around the handle of a weapon the wielder can never unwillingly release their grip.",

"Silvered guardian chain A length of thick silver chain. When wrapped around leather armour it gives +1 armour but clinks loudly.",

"Needle of the savage tailor A tiny, jagged needle that, when pricked into a foe, causes horrific wounds, dealing full class damage. Any attempt to strike when in combat takes -1 to hack and slash. The needle breaks after 3 uses.",

"Flèches d’Achéron 1 munition, 1 poids Fabriquées dans l’obscurité par un artisan aveugle, ces flèches peuvent trouver leur cible même dans les ténèbres les plus profondes.  Un archer peut les tirer dans le noir, sûr de faire mouche les yeux bandés d’un épais tissu. Cependant, si jamais la lumière du soleil venait à toucher ces flèches, celles-ci se disperseraient comme ombre ou poussière.",

"Hache du Roi-Conquérant Proche, 1 poids Elle est faite d’acier étincelant, brillant d’une lumière dorée et est dotée du mythique pouvoir d’autorité. Lorsque vous portez la hache, vous devenez un phare d’inspiration pour tous ceux que vous commandez. Toutes les recrues à votre service ont +1 loyauté, peu importent vos qualités de chef.",

"Pointe du Sombre Portail 0 poids Ce clou ou crochet tordu, à jamais glacé, aurait été arraché, dit-on, du Sombre Portail du Royaume des Morts. Lorsqu’il est planté dans un cadavre, il disparaît et garantit que le cadavre ne sera jamais ressuscité. Nulle magie, exceptée celle de la Mort elle-même, ne peut raviver la flamme de la vie (naturelle ou non) dans ce corps.",

"La Flèche de Carcosa Lancé, 3 poids Personne ne sait d’où provient cette pointe tordue de corail blanc. Ceux qui la portent trop longtemps ont l’esprit encombré de rêves bizarres et se mettent à percevoir les pensées étranges des Autres. Nul n’est à l’abri. Utilisé contre toute cible « naturelle » (humains, gobelins, hibours, etc.) la Flèche agit comme une simple lance. Sa vraie nature est de blesser ces choses que leur nature étrange protège des armes ordinaires. Utilisée ainsi, la Flèche peut blesser des adversaires invulnérables. Le porteur discernera ses ennemis dès qu’il les verra. La Flèche reconnaît les siens.",

"La Cape des Étoiles Silencieuses 1 poids Cette cape parée d’épais velours noir et constellée de petits points lumineux au revers, a la propriété d’infléchir le destin, le temps et la réalité autour d’elle pour protéger le porteur qui peut alors défier le danger avec la caractéristique qu’il préfère. Pour ce faire, l’utilisateur invoque la magie de la cape et décrit comment le manteau l’aide à « tordre les règles ». On peut ainsi dévier une boule de feu avec le CHA en la persuadant qu’on mérite de vivre ou échapper à une chute mortelle en utilisant la puissante logique de son INT pour prouver que la chute ne fera pas mal.  La cape rend tout cela possible. Elle ne peut être utilisée qu’une seule fois pour chaque caractéristique avant de perdre sa magie.",

"Huile de Fléau du Diable 1 utilisation, 0 poids Cette huile sainte a été créée en quantité limitée par une secte de moines montagnards muets dont l’ordre a jadis protégé l’humanité des pouvoirs des profondeurs démoniaques. Il en reste seulement quelques pots. Appliquée à toute arme utilisée pour frapper un habitant d’un plan extérieur, l’huile annule la magie qui lie cette créature.  Dans certains cas, cela la renverra chez elle. Dans d’autres, elle annule simplement la magie qui en assure le contrôle. L’huile reste sur l’arme pendant quelques heures avant de s’évaporer.  Appliquée en cercle ou à l’encadrement d’une porte, l’huile repoussera les créatures des plans extérieurs qui ne pourront la franchir. L’huile dure une journée complète avant d’être absorbée ou de disparaître.",

"La lentille d’Epoch 1 poids Un archimage, trop vieux et faible pour quitter sa tour, conçut ce dispositif complexe et fragile de verre et d’or afin de contempler les antiquités et les reliques qu’il aimait tant. Regarder un objet à travers la lentille procure des visions sur son auteur et son origine.",

"Flacon de Souffle 0 poids Une chose simple mais utile lorsque vous avez besoin d’une bouffée d’air frais. Le flacon semble vide, mais ne peut pas être rempli. Tout ce qui y est ajouté déborde simplement car le flacon est éternellement plein d’air. S’il est placé sous l’eau, il produira des bulles sans arrêt. On peut respirer normalement lorsqu’on le porte à la bouche. La fumée n’est plus un souci, par exemple. Je suis sûr que vous trouverez toutes sortes d’utilisations inhabituelles à cet objet. ",

"La baguette inamovible 0 poids C’est une tige métallique étrange dotée d’un bouton. Appuyez sur le bouton et la tige tient toute seule. Elle se fige sur place dans les airs, à la verticale ou à l’horizontale et ne peut être déplacée.  Tirez-la, poussez-la, essayez aussi fort que vous le souhaitez, la baguette est inamovible. On peut peut-être la détruire, ou pas. Appuyez de nouveau sur le bouton pour la libérer et l’emmener avec vous. Un truc aussi buté peut s’avérer utile.",

"Inspectrices 0 poids Ces lunettes sont faites de verres grossièrement taillés dans une monture en bois. Bien que tordues et presque cassées, elles permettent au porteur de voir bien plus que ses simples yeux ne l’autorisent.  Lorsque vous discernez la réalité avec ces puissants lorgnons, vous parvenez à tordre un peu les règles.  Sur un résultat de 10+, posez trois questions de votre choix. Elles n’ont pas à figurer sur la liste. Le MJ vous dira ce que vous voulez savoir dès lors que cette vision peut vous donner des réponses.",

"La manoeuvre de Ku’meh 1 poids Grand ouvrage de cuir poli par les mains de centaines de généraux, ce livre est souvent transmis de guerrier à guerrier, de père à fils tout au long des batailles qui ont divisé ce monde par le passé. Toute personne qui le lit peut, après l’avoir achevé pour la première fois, lancer 2d6+INT. Sur un 10+, retenez 3. Sur 7-9, retenez 1. Vous pouvez dépenser une retenue pour conseiller un compagnon sur une question d’une importance stratégique ou tactique. Ce conseil vous permet, à tout moment, indépendamment de la distance, de l’aider sur un jet. Sur un échec, le MJ peut retenir 1 et le dépenser pour appliquer un malus de -2 à l’un de vos jets de dés ou à celui du pauvre gars qui aura prêté une oreille à vos conseils.",

"Memento Mori 0 poids Constitué d’une seule mèche de cheveux roux liée par un ruban noir préservé des ravages du temps, le Memento Mori est porteur d’un sombre enchantement. Cet objet contient les souvenirs et les émotions d’une jeune fille qui a négocié tant de fois avec la Mort devant le Sombre Portail qu’à la fin elles sont tombées amoureuses.  Elle a alors quitté le monde pour la rejoindre pendant quelques temps. Son souvenir protège le porteur. S’il se trouve lui-même devant le Sombre Portail, le Memento peut être échangé contre un résultat automatique de 10+ sur l’action dernier soupir.",

"Le Bouclier Aimant +1 armure, 1 poids Quel est l’abruti qui a fabriqué ça ? Les boucliers sont destinés à repousser le métal, pas à l’attirer !  Arborant un lion rampant, le Bouclier Aimant a le pouvoir d’attirer les lames et les flèches à lui. Lorsque vous défendez contre un ennemi qui utilise une arme en métal, vous pouvez dépenser une retenue pour le désarmer. Parfois, une poignée de petite monnaie s’y colle aussi.",

"Larmes d’Anne-Lise 0 poids Les larmes d’Anne-Lise sont des pierres taillées d’un rouge trouble et de la taille d’un ongle. On les trouve toujours par paires. Lorsque chacune est ingérée par deux personnes différentes, cellesci sont liées. Lorsque l’une ressent une émotion forte (en particulier de la tristesse, la perte, la peur ou le désir), l’autre la ressent aussi. Les effets durent jusqu’à ce que l’une verse le sang de l’autre.",

"Armure de Timunn 1 armure, 1 poids Cette armure discrète, qui se fond avec les vêtements, apparaît différemment à chacun. Le porteur semble toujours au dernier cri de la mode pour tous ceux qui le regardent.",

"Suif de Vérité de Titus 0 poids C’est une bougie de suif aux couleurs d’ivoire et de cuivre avec une mèche d’argent tressé.  Lorsqu’elle est allumée, ceux qu’elle éclaire sont incapables de mentir. Ils peuvent garder le silence ou simuler, mais lorsqu’on leur pose une question directe, ils ne peuvent que dire la vérité.",

"Le Miroir d’Argent 0 poids Fabriqué par des orfèvres nains, ce miroir à main métallique est profondément marqué de runes de puissance et de rajeunissement. Destiné à remplacer des membres blessés ou détruits dans des accidents de mines, le Miroir d’Argent se fixe à une blessure, récente ou ancienne. Dur et résistant, il peut être utilisé comme une arme (proche) et contient suffisamment d’argent pur pour nuire aux créatures que cela affecte.",

"Gantelets de Vellius 1 poids Nommés d’après Vellius le Maladroit, Vellius Deux- Mains-Gauches, Vellius l’Empoté, ces gants de tissu simple vous empêchent de lâcher un objet par mégarde. Vous ne pouvez pas être désarmé ni tomber d’une corde ou d’une échelle, par exemple.  Cet objet peut s’avérer particulièrement désagréable si vous agrippez quelque chose de solide alors que quelque chose tire fort sur vos jambes.",

"Glaive d’Intrusion Allonge, 2 poids Cette lame légendaire, que l’on dit avoir été envoyée dans le passé en prévision d’un sombre futur, est forgée d’un étrange acier vert.  La lame frappe l’esprit autant que le corps de ceux qu’elle blesse. Lorsque vous taillez en pièces, sur un 10+ vous gagnez une option supplémentaire : vous pouvez infliger vos dégâts normaux, laisser votre adversaire riposter, et lui insuffler l’émotion de votre choix (peut-être la peur, le respect, ou la confiance).",

"Epée Vorpale Proche, 3 perforant, 2 poids De taille, d’estoc et tout le toutim. Plus tranchante que tout, cette lame d’apparence simple est vouée à séparer une chose de l’autre, le membre d’un corps ou les gens de leur vie. Quand vous infligez des dégâts avec l’Epée Vorpale, votre ennemi doit choisir quelque chose (un objet, un avantage, un membre) et le perdre, définitivement.",

"The Sleep of Reason A small, letter-opener sized blade. Whenever it is drawn from it's sheath, all those nearby, save the bearer, experience severe difficulties with logical and practical thinking. All actions and decisions are penalised except those which are based on strong emotion, unreasoning prejudice or instinct.",

"Shattershard Sword: This sword, as well as injuring its victims in the conventional way, seeds any wounds it makes with multiple small fragments of broken glass. These shards stop the wound from healing naturally, though they can be (painstakingly) picked out by a surgeon with tweezers and magnifying glass over the course of some hours.",

"Necklace of Innocent Speech: This is a necklace made from thirteen tongues of newborn babies, cut free with an obsidian knife and looped onto a cord made from human skin.  When someone wearing the necklace claims to be innocent of a crime that he is guilty of, all within earshot will become convinced that he is telling the truth and is being wrongfully accused. As a secondary effect, the necklace wearer can name someone else, to whom blame will be shifted, no matter how unlikely the story seems. As a conséquence, the guilty will feel sick as hell for several hours (INT 10+), days or permanently suffer internal organ damage. This pain increases After each use.",

"Mirror of Self Image: This mirror shows people as they think they look, rather than how they actually look. The effect is subtle, and anyone regarding their own reflection doesn't notice anything wrong. However, looking at someone else's reflection reveals their idea of their self image, which can give interesting psychological insights.",

"The Broken Heart: This broken golden locket makes whomever wears it an extraordinary composer.",

"The Howling Horn - A silver-inlayed horn, of the kind actually made of a, well, horn. The sound it gives is like a wolf's howl, haunting and fearsome; when blown by the leader of a military unit or similar tightly-knit group, every single member of the group will hear the call no matter where or how far away they are.",

"The Infinite Portal of Rashek the Mad: This item appears as a rectangular frame, roughly the size of a normal door, made up of the twisted and intertwined bodies of people and creatures of every imaginable type (and a few unimaginable types). When activated by the sacrifice of a sufficient number of living creatures of the same type, any who step through the Infinite Portal will be transported to those creatures' home plane of existence.",

"A Blade Called and Sent A small knife pocket knife with a 4 inch stainless blade this weapon can be called to hand with a thought and sent away with one",

"The Bearmaul mace.  One first glance, this seems to be a realtivley ordianry mace, albiet one made using the bones of a bear for it's hilt, with part of the bear's pelt wrapped around to form the grip.  In battle however, the Bearmaul mace reveals why it has it's name - any hit from this mace inflicts injuries on the victim like they had been mauled by a bear, in additon to the standard injuries inclicted by a mace. It also amplifys the strenght of it's weilder, to the point that a solid blow can potentially send a fully armoured knight flying.", 

"Tankard of Languages: Because everybody becomes *more* fluent in a foreign language as their intoxication level increases. Thus, this tankard, when filled with an alcoholic beverage, allows the drinker to understand and converse in any language, so long as they continue to drink during the conversation. The user must drink (sips don't work) approximately once per sentence or response AND per language used during the conversation. This could be problematic for particularly loquacious users... Obviously, the longer the conversation, the drunker the user.  If the user fails to imbibe the required amount, information could be 'lost in translation', miscommunicated, or subtly changed (wrong honorifics applied, pronouns switched, verb tenses altered...). This could have a profound impact on either the user's understanding, or the other conversation's participants' understanding.",

}

return magic

