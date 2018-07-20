
local names = {

  Homme={ 'Aseir', 'Haseid', 'Kheed', 'Zasheir', 'Fodel', 'Glar', 'Grigor', 'Igan', 'Ivor', 'Kosef', 'Mival', 'Pavel', 'Sergor', 'Darvin', 'Dorn', 'Evendur',
'Gorstag', 'Helm', 'Morn', 'Randal', 'Stedd', 'Ander', 'Blath', 'Bran', 'Frath', 'Geth', 'Lander', 'Luth', 'Malcer', 'Stor', 'Taman', 'Bareris', 'Kethoth', 'Mumed', 
'Urhur', 'Borivik', 'Faurgar', 'Jandar', 'Kanithar', 'Madislak', 'Ralmevik', 'Shaumar', 'Vladislak', 'Chen', 'Chi', 'Fai', 'Lian', 'Long', 'Wen', 'Anton', 
'Adran', 'Aelar', 'Aramil', 'Arannis', 'Aust', 'Berrian', 'Carric' , 'Enialis', 'Erdan', 'Erevan', 'Galinndan', 'Hadarai', 'Himo', 'Immeral', 'Laucian', 'Mindartis', 
'Paelias', 'Peren', 'Quarion', 'Riardon', 'Rolen', 'Soveliss', 'Thamior', 'Tharivol', 'Theren', 'Varis', 'Alton', 'Ander', 'Cade', 'Corrin', 'Eldon', 'Errich' , 
'Finnan', 'Garret', 'Lindal', 'Lyle', 'Merric', 'Milo', 'Perrin', 'Reed', 'Roscoe', 'Wellby', 'Agermus', 'Davic', 'Hudis', 'Anvam', 'Egar', 'Dolich', 'Itur',
'Maglo', 'Brattin', 'Hebert', 'Mochor', 'TudonMelyn', 'Ambert', 'Horne', 'Mendes', 'Saber', 'Hygrid', 'Gayle', 'Nairial', 'Jengrid', 'Orcan', 'Eglain', 'Leisman',
'Pelreth', 'Severn', 'Doyle', 'Lemar', 'Peris', 'Tigit', 'Mablain', 'Tronnk', 'Malez', 'Ropire', 'Adech', 'Heran', 'Aluset', 'Darian', 'Kage', 'Shard', 'Aluvin',
'Deorhael', 'Kagi', 'Sland', 'Artina', 'Dresrin', 'Keanan', 'Artine', 'Edbert', 'Kunita', 'Thornelm','Artink', 'Elich', 'Mudarne', 'Tibba', 'Athen','Ogemtown', 
'Cybill', 'Keven', 'Priva', 'Anbog', 'Lito', 'Pultaren', 'Angroc', 'Lear', 'Ronke','Besoth', 'Leat', 'Sengar', 'Bloodvine','Flama', 'Lexis', 'Snorg', 'Meter',
'Tigan', 'Duan' },
 
  Femme={ 'Atala', 'Ceidil', 'Hama', 'Jasmal', 'Meilil', 'Yasheira', 'Zasheida', 'Arveene', 'Esvele', 'Jhessail', 'Kerri', 'Lureene', 'Miri', 'Rowan',
'Tessele', 'Alethra', 'Kara', 'Katernin', 'Mara', 'Natali', 'Olma', 'Tana', 'Zora Betha', 'Cefrey', 'Kethra', 'Mara', 'Olga', 'Silifrey', 'Westra', 'Arizima',
'Chathi', 'Nephis', 'Nulara', 'Murithi', 'Sefris', 'Thola', 'Umara', 'Zolis', 'Hulmarra', 'Immith', 'Imzel', 'Navarra', 'Shevarra', 'Tammith. Yuldra', 'Bai',
'Chao', 'Jia', 'Lei', 'Mei', 'Qiao', 'Shui', 'Tai', 'Balama', 'Dona', 'Faila', 'Jalana', 'Luisa', 'Marta', 'Quara', 'Selise', 'Vonda',  'Adrie', 'Althaea',
'Anastrianna', 'Andraste', 'Antinua', 'Bethrynna', 'Birel', 'Caelynn', 'Drusilia', 'Enna', 'Felosial', 'Ielenia', 'Jelenneth', 'Keyleth', 'Leshanna', 'Lia',
'Meriele', 'Mialee', 'Naivara', 'Quelenna', 'Quillathe', 'Sariel', 'Shanairra', 'Silaqui', 'Theirastra', 'Thia', 'Vadania', 'Valanthe', 'Andry', 'Bree', 'Callie',
'Cora', 'Euphemia', 'Jillian', 'Kithri', 'Lavinia', 'Lidda', 'Merla', 'Nedda', 'Paela', 'Portia', 'Seraphina', 'Shaena', 'Trym', 'Vani', 'Verna' },

  Nain ={ 'Adrik', 'Alberich', 'Baern', 'Barendd', 'Brottor', 'Bruenor', 'Dain', 'Darrak', 'Delg', 'Eberk', 'Einkil', 'Fargrim', 'Flint', 'Gardain',
'Harbek', 'Kildrak', 'Morgran', 'Orsik', 'Oskar', 'Rangrim', 'Rurik', 'Taklinn', 'Thoradin', 'Thorin', 'Tordek', 'Travok', 'Ulfgar', 'Veit', 'Vondal' },

  Naine={ 'Amber', 'Artin', 'Audhild', 'Bardryn', 'Diesa', 'Eldeth', 'Falkrunn', 'Finellen', 'Gunnloda', 'Gurdis', 'Helja', 'Hlin', 'Kathra',
'Kristryd', 'Ilde', 'Liftrasa', 'Mardred', 'Riswynn', 'Sannl', 'Torbera', 'Torgga', 'Vistra' },

  Clan={  'Marteau De Guerre', 'Nuqueroide', 'Coeursang', 'Forgefeu', 'Barderaide', 'Gorunn', 'Oeil D’aigle','Poing de Fer', 'Loderr', 'Lutgehr',
'Rumnaheim', 'Strakeln', 'Torunn', 'Ungart'},

  Orc= { 'Dench', 'Feng', 'Gell', 'Henk', 'Holg', 'Imsh', 'Keth', 'Krusk', 'Mhurren', 'Ront', 'Shump', 'Thokk' },

  Ville= { 'Amar', 'Bremere', 'Delif', 'Falshire', 'Halenshire', 'Kheadesh', 'Lindellin', 'Meadowbrook', 'Quin-La', 'Stinglad', 'Styrewood', 'Thandor',
'Edgewater', 'Restan', 'Lockhart', 'Engelhard', 'Lingle', 'Brookville', 'Diggins', 'Claremore', 'Ballico', 'Palos', 'Brigman', 'Ingleside', 'Sikeston', 'Lattimere',
'Addis', 'Tooelle', 'Inglees', 'Jubarr', 'Kepol', 'Oulob', 'Melnith', 'Nabbar', 'Vlance' },

  Taverne={ 'Le Fou', 'La Licorne Enivrée', 'Le Barbare et le Marteau', 'Le Serpent Moqueur', 'Au Crabe Sauvage', 'Le Grand Golem', 'Le Duché', 'La Fière Statue',
'La Chauve Sourist', 'Au Poisson Enivré' },

}

return names


