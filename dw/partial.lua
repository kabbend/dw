
local partial = {
'01. Tu frappes ton adversaire mais dans ta précipitation, tu t’avances trop et maintenant il te domine, son bras levé prêt à s’abattre sur ta nuque',
'02. Tu frappes ton adversaire mais ton élan t’entraines trop loin, et maintenant tu lui tournes le dos',
'03. Tu frappes ton adversaire mais tu as mal dosé ta force, il prend un coup qui le désarçonne mais toi tu entends les os de ton épaule craquer, et tu ressens une forte douleur',
'05. Tu frappes ton adversaire mais ton arme reste coincée dans son armure (dans son sac, dans son épaule…)',
'06. Tu frappes si violemment que l’anse de ton sac craque et qu’il tombe lourdement sur le sol',
'07. Tu frappes si violemment que l’anse de ton sac craque et que son contenu se répand en roulant et cliquetant à des mètres à la ronde',
'08. Tu frappes ton adversaire et le t’approchant si près que, au moment de faire un pas de recul, tu t’aperçois que ton sac est resté coincé dans son bras, et que tu ne peux plus t’éloigner',
'09. Tu frappes ton adversaire mais son sang et sa sueur t’aveuglent l’espace d’un instant',
'10. Tu frappes ton adversaire en poussant un tel cri involontaire, que l’assistance proche se retourne vers toi et te scrute soudainement',
'11. Tu frappes ton adversaire mais ton élan est trop fort, et tu pars en avant sans controler ton mouvement, jusqu’à te cogner contre un obstacle ou un compagnon',
'12. Tu frappes ton adversaire mais, si le coup ne l’as pas tué, maintenant tu l’as mis en rage',
'13. Tu frappes ton adversaire mais ta prise était un peu faible, et il en profite pour te faire un coup bas douloureux sans être trop dangereux (coup de genou, morsure à la main…)',
'14. Tu frappes ton adversaire et il pousse un tel cri de douleur qu’il fige les adversaires alentour, qui maintenant t’on mis en joue',
'15. Tu frappes ton adversaire si violemment que vous tombez tous les deux à la renverse, heureusement lui en dessous',
'16. Tu frappes ton adversaire si violemment que vous tombez tous les deux à la renverse, toi coincé dessous',
'17. Tu frappes ton adversaire, mais même blessé il pousse un rire qui galvanise les adversaires',
'18. Tu frappes ton adversaire mais le choc te fait perdre ton arme',
'19. Tu frappes ton adversaire mais vous vous cognez la tête l’un l’autre, et vous restez groggy l’espace d’un instant, le plus résistant repartira au combat le premier',
'20. Tu frappes ton adversaire mais quand tu enfonces ton arme, lui t’enserres de ses bras et cherche à t’immobiliser',
'21. Tu frappes ton adversaire qui recule lourdement, mais il te cachait un autre acolyte qui surgit et te tombe dessus en furie',
'22. Tu frappes ton adversaire avec tellement de fougue que tu n’as pas vu que lui, dans le meme temps, a pointé une lame sur ta gorge',
'23. Tu frappes ton adversaire mais, en vous débattant l’un l’autre, vous vous éloignez de la zone de combat et vous retrouvez maintenant un peu isolés',
'24. Tu frappes mais mal, tes vêtements se prennent dans le combat et ils se déchirent violemment, tu es à moitié nu maintenant',
'24. Tu frappes mais mal, tu es déséquilibré et tu tombes sur un piège à proximité',
'25. Tu frappes mais le choc est trop important, ton arme se tord…',
'26. Tu frappes mais le choc est trop important, tu titubes en reculant, le nez en sang',
'27. Tu frappes mais tu t’approches trop, ton adversaire hurle et crie dans ton visage, tu recules de dégout et de surprise',
'28. Tu frappes mais tu entends les cris d’autres adversaires qui arrivent, non loin de là',
'29. Tu frappes mais tu réalises que ton adversaire t’as entrainé un peu trop loin et tu commences à être encerclé maintenant',
'30. Tu frappes mais tu comprends qu’il faut, soit retenir ton coup (degats/2), soit aller jusqu’au bout mais ton adversaire va s’écrouler sur un de tes compagnons',
'31. Tu frappes mais tu comprends qu’il faut, soit retenir ton coup (degats/2), soit te laisser aller en avant mais risquer de t’affaler de tout ton long',
'32. Tu frappes mais tu comprends qu’il faut, soit dévier ton coup (degats/2), soit risquer de blesser un compagnon tellement ton geste est puissant et incontrolé',
'33. Tu frappes mais tu comprends qu’il faut, soit retenir ton coup (degats/2), soit subir une contre attaque dangereuse car ton adversaire cherchait une faille pendant tout ce temps',
'34. Tu frappes mais tu comprends qu’il faut, soit faire un mouvement de coté (degats/2), soit subir une attaque à distance de plusieurs archers restés en arrière',
'35. Tu frappes mais tu comprends qu’il faut, soit retenir ton coup (degats/2), soit resté accroché à ton adversaire qui cherche à t’agripper par tous les moyens',
'36. Tu frappes mais tu comprends qu’il faut, soit retenir ton coup (degats/2), soit glisser et risquer de tomber au sol avec ton adversaire',
'37. Tu frappes mais tu dois choisir entre retenir ton coup (degats/2), soit lâcher ton sac',
'38. Tu frappes mais tu dois choisir entre porter ton coup à pleine force, soit porter secours à un allié proche mais dégats/2',
'39. Tu frappes mais tu dois choisir entre porter ton coup à pleine force et endommager une de tes pièces d’armure, soit retenir ton coup (degats/2)',
'40. Tu frappes mais tu dois choisir entre retenir ton coup , soit laisser ton arme cogner à pleine force une partie armurée que tu n’avais pas vu et risquer de la briser',
'41. Tu frappes mais votre élan vous entraine à chuter au beau milieu de la bataille',
'42. Tu frappes mais votre élan vous entraine à chuter au beau milieu d’adversaires enragés',
'43. Tu frappes mais les cris de ton infortuné adversaire semblent attirer les cris d’une autre bête, plus puissante semble-t-il',
'44. Tu frappes mais les cris de ton infortuné adversaire semblent déclencher des bruits de tambour à proximité',
'45. Tu frappes mais à mesure que ton arme s’enfonce, les yeux de ton adversaire se révulsent et il psalmodie une puissante incantation…',
'46. Tu frappes mais à mesure que ton arme s’enfonce, tu vois une bête jaillir sur son épaule et s’abattre sur toi',
'47. Tu frappes si violemment que ton adversaire cogne un élément de décor, au point de le faire tomber ou écrouler…',
'48. Tu frappes mais au même moment, tu entrevois le liquide visqueux et empoisonné qui imprègne la lame de ton adversaire…',
'49. Tu frappes mais au même moment, tu entrevois les runes magiques que ton adversaire porte sur son visage, ses bras et son torse',
'50. Tu frappes mais au même moment, tu entends les incantations magiques que quelqu’un psalmodie derrière les lignes ennemies',
'51. Tu frappes mais au même moment, tu entrevois un autre adversaire surgir de l’obscurité et se jeter sur toi, dans ton angle de vision',
'52. Tu frappes mais au même moment, tu ressens une crampe ou un claquage, et tu te figes en grimaçant',
'53. Tu frappes mais au même moment, ton adversaire t’agrippe par les cheveux et te fait hurler de douleur',
'54. Tu frappes mais au même moment, tu entends le souffle d’un autre adversaire qui vient de se glisser discrètement dans ton dos',
'55. Tu frappes mais tu entends le claquement d’un mécanisme et d’une lame qui jaillit du bras de ton adversaire, tout prêt de ton visage',
'56. Tu frappes mais la sueur coule dans ta main, et le pommeau de ton arme commence à glisser, coincée dans l’armure de ton adversaire',
'57. Tu frappes mais la sueur coule dans tes sourcils et sur tes yeux qui te brulent, tu commences à voir flou et tu dois reculer',
'58. Tu frappes mais ton casque glisse et se retrouve de guinguois, il te masque un oeil maintenant',
'59. Tu frappes mais la lanière de ton casque se détache et ton casque roule lourdement sur le sol',
'60. Tu frappes mais la lanière de ta sandale se détache et ta chaussure disparait au loin, tu es déséquilibré et à moitié pied nu',
'61. Tu frappes mais il a répliqué en frappant lourdement une pièce d’armure, qui s’est déformée sous le choc et qui te fait mal maintenant. Tu dois t’en séparer ou souffrir au moindre mouvement',
'62. Tu frappes mais, si tu étais resté discret ou caché jusque là, tu es maintenant en pleine lumière',
'63. Tu frappes mais, si tu étais resté discret ou caché jusque là, tu réalises avec effroi que tu n’étais pas le seul à t’être glissé dans cette cachette, un adversaire jaillit près de toi',
'64. Tu frappes mais ton adversaire te jette au visage, dans un geste de défense, un sac plein d’affaires bringuebalantes, tu es désarçonné ',
'65. Tu frappes mais la violence du coup te vrille le bras, tu as mal maintenant',
'66. Tu frappes mais un élément de vetement (manche, cape, chaussure) reste coincé dans un élément de décor, tu dois prendre une décision sur quoi faire',
'67. Tu frappes mais pour se défendre ton adversaire t’enserre la tête avec une pièce de vetement, tu es temporairement aveuglé et empêtré',
'68. Tu frappes mais tu réalises à ce moment que tu n’avais pas bien jaugé ton adversaire, maintenant tu vois clairement qu’il a une Mutation (table ci dessous)',
'69. Tu frappes ton adversaire qui recule et est sur le point de tomber dans un piège ! Seulement voilà, s’il se déclenche le piège est tout aussi dangereux pour toi !',
'70. Tu frappes ton adversaire jusqu’au point de rentrer en contact avec lui, et là tu t’aperçois qu’il est porteur d’une grave maladie contagieuse (lèpre, peste…)',
'71. Tu frappes mais ton adversaire te jette du sable ou de la poussière dans les yeux, tu es aveuglé',
'72. Tu frappes mais ton geste est trop brutal et tu cognes violemment un compagnon, vous voilà méchamment sonnés tous les deux',
'73. Tu frappes ton adversaire mais tu comprends qu’il doit être drogué, il ne semble pas ressentir la douleur et son regard est fou',
'74. Tu frappes mais ton adversaire riposte par un violent coup sur ton oreille, une vibration assourdissante envahit ta tête et tu n’entends rien d’autre, tu es sonné',
'75. Tu frappes violemment mais tu entends des objets fragiles se casser (ou se déchirer) dans ton sac',
'76. Tu frappes mais la violence du coup te projette sur un compagnon, dont tu viens d’écraser le sac dans un bruit de casse ou de déchirure',
'77. Tu frappes ton adversaire mais tu entends le clinquement de toutes tes pièces d’or qui tombent et roulent sur le sol à vos pieds',
'78. Tu frappes mais tu te replaces mal et la lame de ton adversaire plonge dans ton cou, que fais-tu ?',
'79. Tu frappes mais tu te replaces mal et ton adversaire t’a attrapé d’une main par le cou et commence à t’étrangler / te soulever, , que fais-tu ?',
'80. Tu frappes mais tu te replaces mal et ton adversaire jette son poing contre ton nez, , que fais-tu ?',
'81. Tu frappes mais tu te replaces mal et ton adversaire jette son bouclier contre ton visage, que fais-tu ?',
'82. Tu frappes mais tu te replaces mal et ton adversaire va abattre son arme sur ton dos, que fais-tu ?',
'83. Tu frappes mais tu te replaces mal et ton adversaire a disparu de ton champ de vision lorsque tu tournes la tête, que fais tu ?',
'84. Tu frappes mais tu te replaces mal et ton adversaire se jette sur toi pour te renverser, que fais tu ?',
'85. Tu frappes mais ton adversaire a eu le temps de sortir une deuxième lame, qu’il jette de toutes ses forces sur toi, que fais tu ?',
'86. Tu frappes mais ton adversaire se jette tête baissée sur toi, et tu réalises soudain à quoi sert la pointe métallique. Que fais tu ?',
'87. Tu frappes mais ton adversaire a brusquement fait passer sa lame d’une main à l’autre, et tu te retrouves sans la protection de ton armure. Que fais tu ?',
'88. Tu frappes mais tu entrapercois un lourd objet (bloc, tronc, pierre, métal) venir s’écraser sur toi / vous depuis le fond de la scène. Que fais tu ?',
'89. Tu frappes mais ton adversaire vient au contact et cherche à te renverser, que fais tu ?',
'90. Tu frappes mais ton adversaire leve ses deux bras pour te fracasser la tête, que fais tu ?',
'91. Tu frappes mais ton adversaire entame un terrible uppercut au menton, que fais tu ?',
'92. Tu frappes mais ton adversaire a le temps de reculer et de te lancer une lame vers le torse, que fais tu ?',
'93. Tu frappes mais au moment où tu retires ta lame, un autre adversaire que tu n’avais pas vu tombe lourdement sur toi et vous roulez sur le sol, le premier adversaire restant prêt à attaquer',
'94. Tu frappes mais au moment où tu retires ta lame, un autre adversaire que tu n’avais pas vu t’agrippe les bras par derriere et tu es à leur merci',
'95. Tu frappes mais au moment où tu retires ta lame, tu entends les flèches filer vers toi, elles ne t’épargneront ni toi ni ton infortuné adversaire',
'96.',
'97.',
'98.',
'99.',
'00. Au moment où tu frappes, tu comprends que tu viens de t’en prendre à un être possédé par une entité démoniaque',
}

return partial

