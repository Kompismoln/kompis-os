# Personuppgiftsbiträdesavtal

## 0. Intro till Kompismoln som personuppgiftsbiträde
Det här avtalet är till för de tjänster på kompismoln som hanterar personuppgifter.

Det är en förenklad version av [kommarkollegiets mall](https://www.avropa.se/contentassets/5eac48219db440f38e6a91c722151cd5/mall-for-personuppgiftsbitradesavtal.docx) och reglerar fördelningen mellan de som ansvarar för en tjänst och de som ansvarar för den underliggande tekniken.

**tldr;** Ni identifierar vilka personuppgiftstyper som ska hanteras och väljer ut en lämplig laglig grund för varje personuppgiftstyp.
Utifrån detta skriver ni först en integritetspolicy enligt separata direktiv, och sedan en instruktion för hur jag som ert personuppgiftsbiträde
ska hantera personuppgiftstyperna, t.ex.:

**Personuppgiftstyp 1 - Användaruppgifter + profil:**
- Syften: För plattformens funktion, moderering
- Uppgifter: E-post, lösenord (hash), profiltext, meddelanden
- Backup: 24h
- Retention: 6 månader

**Personuppgiftstyp 2 - Besöksloggar:**
- Syften: Anpassningar för ökad tillgänglighet, diagnostik
- Uppgifter: IP-adress, REQUEST, login
- Retention: 1 månad (aggregerad 1 år)

Jag åtar mig sedan att hantera uppgifterna i enlighet med instruktionerna och EU:s dataskyddsförordning (EU) 2016/679,
medan ni fortsätter ansvara för att hanteringen av personuppgifter sker på en laglig grund.

Läs mer om vilka åtaganden som följer personuppgiftsansvar under kapitel 3. Läs gärna resten av avtalet också,
det handlar om era och era registranters rättigheter samt kriterier som infrastrukturen bakom kompismolnet måste uppfylla.


## 1. Allmänt om Personuppgiftsbiträdesavtalet

**1.1** Detta personuppgiftsbiträdesavtal reglerar personuppgiftsbiträdets behandling av personuppgifter för den personuppgiftsansvariges räkning enligt kraven i EU:s dataskyddsförordning (EU) 2016/679.

**1.2** Instruktion till personuppgiftsbiträdesavtalet fylls i av parterna för att kraven i Dataskyddsförordningen ska kunna uppfyllas.

**1.3** Personuppgiftsbiträdesavtalet gäller behandlingar av personuppgifter som personuppgiftsbiträdet utför för den personuppgiftsansvariges räkning. Dessa behandlingar förtecknas i avsnitt 1 Instruktionen. Alla behandlingar av personuppgifter enligt Personuppgiftsbiträdesavtalet omfattas av Dataskyddsförordningen, dataskyddslagen och kompletterande lagstiftning (sammantaget benämnt ”Dataskyddsregleringen”).

## 2. Parter

**Personuppgiftsansvarig:**
- Namn:
- Adress:
- Telefonnummer:
- E-postadress:
- Organisationsnummer:

**Personuppgiftsbiträde:**
- Namn: Alexander Holmbäck (Kompismoln)
- Adress: Hornsbruksgatan 9
- Telefonnummer: 0707976262
- E-postadress: alex@kompismoln.se
- Organisationsnummer: 8208250434


## 3. Den personuppgiftsansvariges generella åtaganden
**3.1** Den personuppgiftsansvarige ansvarar för att det vid var tid finns laglig grund för behandlingen och för att utforma korrekta instruktioner så att personuppgiftsbiträdet kan fullgöra sitt uppdrag enligt Personuppgiftsbiträdesavtalet.

**3.2** Den personuppgiftsansvarige ansvarar för att informera registrerade om behandlingen, tillvarata den registrerades rättigheter samt att vidta varje annan åtgärd som åligger den personuppgiftsansvarige enligt Dataskyddsregleringen.

## 4. Personuppgiftsbiträdets generella åtaganden
**4.1** Personuppgiftsbiträdet garanterar att dennes verksamhet bedrivs på ett sätt som säkerställer Dataskyddsregleringens krav på lämpliga tekniska och organisatoriska åtgärder och att den registrerades rättigheter skyddas. Personuppgiftsbiträdet garanterar att det har tillräcklig kunskap och förfogar över tillräckliga resurser för att Dataskyddsregleringens krav ska kunna tillgodoses.

**4.2** Vid bedömningen av lämplig säkerhetsnivå ska särskild hänsyn tas till risken för oavsiktlig eller olaglig förstöring, förlust eller ändring eller obehörig åtkomst till den personuppgiftsansvariges personuppgifter.

**4.3** Personuppgiftsbiträdet ska under alla förutsättningar vidta de säkerhetsåtgärder som framgår nedan, punkterna 4.4-4.9.

**4.4** När personuppgiftsbiträdets egen utrustning (t.ex. bärbara datorer för administration) inte står under uppsikt ska den skyddas mot obehörig åtkomst. För servrar och infrastruktur som tillhandahålls av underbiträde (t.ex. datacenter) gäller underbiträdets säkerhetsföreskrifter och certifieringar.

**4.5** Personuppgifterna ska regelbundet överföras till säkerhetskopior. Kopiorna ska förvaras avskilt och väl skyddade så att personuppgifterna kan återskapas. Personuppgiftsbiträdet ska ha en rutin för regelbunden test av återläsning.

**4.6** Ett tekniskt system för behörighetskontroll ska styra åtkomsten till personuppgifterna för personuppgiftsbiträdet. Användaridentitet ska vara personlig och får inte överlåtas på någon annan. Det ska finnas rutiner för tilldelning och borttagande av behörigheter. Åtkomst till personuppgifter ska kunna följas upp genom en logg eller liknande underlag. Underlaget ska kunna kontrolleras av personuppgiftsbiträdet och återrapporteras till den personuppgiftsansvarige.

**4.7** Anslutning för extern datorkommunikation ska skyddas med sådan teknisk funktion som säkerställer att uppkopplingen är behörig. För åtkomst till känsliga personuppgifter krävs stark autentisering. Personuppgifter som överförs via datorkommunikation utanför lokaler som kontrolleras av personuppgiftsbiträdet ska skyddas med kryptering.

**4.8** När fasta eller löstagbara lagringsmedier, som innehåller personuppgifter, inte längre ska användas för sitt ändamål ska personuppgifterna raderas på sådant sätt att de inte kan återskapas.

**4.9** Om personuppgiftsbiträdet får överföra personuppgifter till eller behandla personuppgifter i tredje land ska det framgå av Instruktionen. Parterna måste i den situationen komma överens om en lämplig rättslig lösning för att överföringen till eller behandlingen i tredje land ska vara tillåten (jfr kap. V Dataskyddsförordningen eller motsvarande dataskyddsreglering).

**4.10** Ytterligare preciseringar av tekniska och organisatoriska säkerhetsåtgärder ska framgå av avsnitt 3 Instruktionen samt av övriga avtalshandlingar.

## 5. Behandling av personuppgifter
**5.1** Personuppgiftsbiträdet får inte behandla den personuppgiftsansvariges personuppgifter på något annat sätt, för andra ändamål eller enligt andra instruktioner än de som framgår av Personuppgiftsbiträdesavtalet, inklusive avsnitt 1 Instruktionen. Behandlingen av personuppgifter ska ske med iakttagande av de tekniska och organisatoriska säkerhetsåtgärder som följer av Personuppgiftsbiträdesavtalet och avsnitt 3 Instruktionen.

Första stycket gäller inte om en behandling krävs enligt unionsrätten eller enligt en medlemsstats nationella rätt som personuppgiftsbiträdet omfattas av. I sådana fall ska personuppgiftsbiträdet informera den personuppgiftsansvarige om det rättsliga kravet innan uppgifterna behandlas, såvida sådan information inte är förbjuden med hänvisning till ett viktigt allmänintresse enligt denna rätt. Innan personuppgiftsbiträdet behandlar personuppgifter enligt andra stycket ska personuppgiftsbiträdet ha gjort en kvalificerad rättslig prövning av om behandlingen får ske. I tveksamma fall eller om prövningen visar att behandlingen inte får ske, ska personuppgiftsbiträdet motsätta sig det rättsliga kravet på behandling för att erhålla ett lagakraftvunnet avgörande i syfte att säkerställa den registrerades rättigheter.

**5.2** För det fall att personuppgiftsbiträdet finner att instruktioner är otydliga, i strid med Dataskyddsregleringen eller saknas och personuppgiftsbiträdet bedömer att nya eller kompletterande instruktioner är nödvändiga för att genomföra sina åtaganden ska personuppgiftsbiträdet utan dröjsmål informera den personuppgiftsansvarige, tillfälligt upphöra med behandlingen och invänta nya instruktioner. 

**5.3** Personuppgiftsbiträdet åtar sig, att i sin verksamhet, vid var tid tillse att berörd personal följer Personuppgiftsbiträdesavtalet och att de hålls informerade om innehållet i Dataskyddsregleringen.

**5.4** Personer som utför arbete under personuppgiftsbiträdets överinseende, t.ex. som anställda, och som får tillgång till personuppgifter, får endast behandla uppgifterna enligt den personuppgiftsansvariges instruktioner, såvida inte en skyldighet att göra något annat krävs enligt unionsrätten eller enligt en medlemsstats nationella rätt som personuppgiftsbiträdet omfattas av. I sådana fall ska personuppgiftsbiträdet informera den personuppgiftsansvarige om det rättsliga kravet innan uppgifterna behandlas, såvida sådan information inte är förbjuden med hänvisning till ett viktigt allmänintresse enligt denna rätt. Endast personer som behöver uppgifterna för att kunna utföra sina arbetsuppgifter ska ges sådan tillgång.

**5.5** Personuppgiftsbiträdet garanterar att personer som får tillgång till personuppgifter har åtagit sig att iaktta konfidentialitet eller omfattas av lämplig lagstadgad tystnadsplikt.

**5.6** Personuppgiftsbiträdet ska efter den personuppgiftsansvariges beslut om radering av personuppgifter avlägsna dessa permanent från alla lagringsmedier som biträdet förfogar över. Detta ska ske snarast, dock senast 30 dagar efter beslutet om radering. Som beslut om radering räknas t.ex. att uppgifter har raderats via användargränssnittet i den tjänst som omfattas av kontraktet.

## 6. Den registrerades rättigheter
**6.1** Personuppgiftsbiträdet ska på begäran från den personuppgiftsansvarige bistå denne med att säkerställa att skyldigheterna enligt art. 32-36 Dataskyddsförordningen fullgörs och svara på begäran om utövande av den registrerades rättigheter i enlighet med kap. III Dataskyddsförordningen. Detta ska göras med beaktande av typen av behandling och den information som personuppgiftsbiträdet har att tillgå.

## 7. Personuppgiftsincidenter
**7.1** Personuppgiftsbiträdet ska ha förmåga att återställa tillgängligheten och tillgången till personuppgifterna i rimlig tid vid en fysisk eller teknisk incident enligt art. 32.1 c Dataskyddsförordningen.

**7.2** Personuppgiftsbiträdet åtar sig att, med beaktande av behandlingens art och den information som personuppgiftsbiträdet har att tillgå, bistå den personuppgiftsansvarige med att fullgöra dennes skyldigheter vid en personuppgiftsincident beträffande behandlingen. Personuppgiftsbiträdet ska på den personuppgiftsansvariges begäran även bistå med att utreda misstankar om eventuell obehörig behandling och/eller åtkomst till personuppgifterna. 

**7.3** Vid personuppgiftsincidenter, vilka personuppgiftsbiträdet fått vetskap om, ska personuppgiftsbiträdet utan onödigt dröjsmål skriftligen underrätta den personuppgiftsansvarige om händelsen. Personuppgiftsbiträdet ska med beaktande av typen av behandling och den information som personuppgiftsbiträdet har att tillgå tillhandahålla den personuppgiftsansvarige en skriftlig beskrivning av personuppgiftsincidenten. 

Beskrivningen ska minst redogöra för:
1. personuppgiftsincidentens art och, om möjligt, de kategorier och antalet registrerade som berörs samt kategorier och antalet personuppgiftsposter som berörs,
2. de sannolika konsekvenserna av personuppgiftsincidenten, och
3. åtgärder som har vidtagits till följd av personuppgiftsincidenten, förslag för att ytterligare åtgärda personuppgiftsincidenten samt förslag på åtgärder för att mildra personuppgiftsincidentens potentiella negativa effekter.

## 8. Tillsyn och revision 
**8.1** För det fall registrerade, tillsynsmyndigheten eller annan tredje man begär information från personuppgiftsbiträdet som rör behandlingen av personuppgifter, ska personuppgiftsbiträdet hänvisa till den personuppgiftsansvarige. Personuppgiftsbiträdet får inte lämna ut personuppgifter eller annan information om behandlingen av personuppgifter utan uttrycklig instruktion från den personuppgiftsansvarige, såvida inte en sådan utlämnandeskyldighet krävs enligt unionsrätten eller enligt en medlemsstats nationella rätt som personuppgiftsbiträdet omfattas av. I sådana fall ska personuppgiftsbiträdet informera den personuppgiftsansvarige om det rättsliga kravet innan uppgifterna behandlas, såvida informationen inte är förbjuden med hänvisning till ett viktigt allmänintresse enligt denna rätt.

**8.2** Personuppgiftsbiträdet ska utan dröjsmål informera den personuppgiftsansvarige om eventuella kontakter med tillsynsmyndigheten som rör, eller kan vara av betydelse för, personuppgiftsbiträdes behandling av personuppgifter. Åtagandet gäller inte om personuppgiftsbiträdet är förhindrat att lämna den aktuella informationen enligt tvingande lagstiftning.

**8.3** Personuppgiftsbiträdet har inte rätt att företräda den personuppgiftsansvarige eller agera för dennes räkning gentemot tillsynsmyndigheten.

**8.4** Den personuppgiftsansvarige äger rätt att själv eller genom en utsedd oberoende tredje part följa upp att personuppgiftsbiträdet uppfyller Personuppgiftsbiträdesavtalets, Instruktionens och Dataskyddsregleringens krav. Personuppgiftsbiträdet ska vid sådan granskning bistå den personuppgiftsansvarige, eller den som utför granskningen i den personuppgiftsansvariges ställe, med dokumentation, tillgång till lokaler, IT-system och andra tillgångar som behövs för att kunna granska personuppgiftsbiträdets efterlevnad av Personuppgiftsbiträdesavtalet, Instruktionen och Dataskyddsregleringen.
Den personuppgiftsansvarige ska säkerställa att personal som genomför granskningen är underkastad konfidentialitet enligt lag eller avtal.
Gällande infrastruktur som tillhandahålls av underbiträde (t.ex. Hetzner) fullgörs rätten till granskning primärt genom att personuppgiftsbiträdet tillhandahåller relevanta certifikat eller revisionsrapporter från underbiträdet.

## 9. Behandling med hjälp av underbiträden
**9.1** Personuppgiftsbiträdet äger endast rätt att anlita ett annat personuppgiftsbiträde (underbiträde) för behandlingen av personuppgifter om detta anges i Instruktionen.

**9.2** Den personuppgiftsansvarige har i och med Personuppgiftsbiträdesavtalets ikraftträdande godkänt de underbiträden som angivits i Instruktionen.

**9.3** Om personuppgiftsbiträdet med stöd i Personuppgiftsbiträdesavtalet anlitar ett underbiträde för hela eller en del av behandlingen ska underbiträdet genom avtal åläggas samma skyldigheter avseende dataskydd som de som fastställs i Personuppgiftsbiträdesavtalet och vid varje tidpunkt gällande instruktioner rörande behandlingen.

**9.4** Vid en begäran om att få anlita ett nytt underbiträde ska personuppgiftsbiträdet lämna den personuppgiftsansvarige all relevant information om det föreslagna underbiträdet som krävs för en dataskyddsrättslig bedömning. Information ska därvid särskilt lämnas om i vilket land som underbiträdet kommer att behandla personuppgifterna och vilka typer av behandlingar som underbiträdet är tänkt att utföra.

**9.5** Personuppgiftsbiträdet ska tillse att underbiträde inte anlitar ett annat underbiträde utan den personuppgiftsansvariges skriftliga förhandstillstånd.

**9.6** Personuppgiftsbiträdet ska hålla en förteckning över de underbiträden som vid varje aktuell tidpunkt anlitas, samt göra denna förteckning tillgänglig för den personuppgiftsansvarige. Av förteckningen ska särskilt framgå vilka typer av behandlingar som underbiträdet utför, i vilka länder som underbiträdet behandlar personuppgifterna samt, om överföringar till tredje land kan förekomma, vilken rättslig lösning som då används enligt kap. V Dataskyddsförordningen. På begäran ska personuppgiftsbiträdet lämna den personuppgiftsansvarige information om ett underbiträdes rättsliga åtaganden samt övrig information som krävs för att den personuppgiftsansvarige ska kunna fullgöra sina skyldigheter enligt Dataskyddsregleringen.

**9.7** Om ett underbiträde inte fullgör sina skyldigheter avseende dataskydd är personuppgiftsbiträdet fullt ansvarigt i förhållande till den personuppgiftsansvarige.

## 10. Skyldigheter efter kontraktets upphörande
**10.1** I samband med kontraktets upphörande ska personuppgifterna återlämnas till den personuppgiftsansvarige såvida inte denne uttryckligen önskar att uppgifterna ska raderas. Efter att personuppgifter har återlämnats eller raderats ska eventuella kopior raderas från använda lagringsmedier på ett sådant sätt att uppgifterna inte längre kan återskapas. Denna åtgärd ska vara fullt genomförd senast 30 dagar efter kontraktets upphörande.

**10.2** Såvida inte annat avtalats eller uppenbart följer av omständigheterna, ska personuppgifterna överlämnas i ett format som är läsbart och möjligt att använda i andra sammanhang. Detta innebär att, utöver personuppgifterna, även all annan logisk information som behövs för att kunna nyttja personuppgifterna ska tillhandahållas. Vidare ska också loggfiler, revisionsdata, accessdata och liknande metadata tillhandahållas. Även sådan data ska lämnas i ett sådant format att den är användbar för den personuppgiftsansvarige.

**10.3** Personuppgiftsbiträdet ska på den personuppgiftsansvariges eller en behörig tillsynsmyndighets begäran ställa relevanta delar av använda lagringsmedium till förfogande för en granskning av de åtgärder som anges i punkt 11.1.

## 11. Giltighetstid och ändringar
**11.1** Den personuppgiftsansvarige har rätt att påkalla ändring av Personuppgiftsbiträdesavtalet. 

**11.2** Personuppgiftsbiträdesavtalet gäller från undertecknandet och så länge som personuppgiftsbiträdet behandlar den personuppgiftsansvariges personuppgifter.

## 12 Ansvar för skada i samband med behandling
**12.1** Vid ersättning för skada i samband med behandling som, genom fastställd dom eller beslut, utgått till den registrerade på grund av överträdelse av bestämmelse i Personuppgiftsbiträdesavtalet, Instruktionen och/eller bestämmelse i Dataskyddsregleringen ska art. 82 Dataskyddsförordningen tillämpas. 

**12.2** Sanktionsavgifter ska enligt art. 83 Dataskyddsförordningen, eller 6 kap. 2 § lagen (2018:218) med kompletterande bestämmelser till Dataskyddsförordningen bäras av den av personuppgiftsbiträdesavtalets parter som påförts en sådan avgift. 

**12.3** Part som får kännedom om omständighet som kan leda till skada för motparten ska omedelbart informera motparten om förhållandet och aktivt arbeta tillsammans med motparten för att förhindra och minimera sådan skada. 

**12.4** Personuppgiftsbiträdets skadeståndsansvar gentemot den personuppgiftsansvarige ska per kalenderår vara begränsat till ett belopp motsvarande den totala ersättning som betalats under de senaste 12 månaderna. Denna begränsning gäller inte vid uppsåt eller grov vårdslöshet.

# Instruktion till personuppgiftsbiträdesavtalet
Denna del utgör den personuppgiftsansvariges instruktioner till personuppgiftsbiträdet.
[Fyll i]


## Behandling med hjälp av underbiträden
Välj ett av alternativen nedan.
- [ ] Personuppgiftsbiträdet äger inte rätt att anlita ett annat personuppgiftsbiträde (underbiträde) enligt denna instruktion.
- [ ] Personuppgiftsbiträdet får endast anlita ett annat personuppgiftsbiträde om ett skriftligt förhandstillstånd har inhämtats från den personuppgiftsansvarige.
- [x] Personuppgiftsbiträdet har en allmän rätt att anlita ett nytt personuppgiftsbiträde (underbiträde), som uppfyller dataskyddsregleringen och personuppgiftsbiträdesavtalets krav. Ett nytt underbiträde får emellertid endast anlitas efter det att den personuppgiftsansvarige har underrättats om planerna och givits möjlighet att inom skälig tid göra invändningar mot valet.

## Behandling av personuppgifter inom Sverige, EU/EES samt tredje land
Väj ett av alternativen nedan.
- [ ] Personuppgifter får endast behandlas inom Sverige.
- [x] Personuppgifter får endast behandlas inom EU/EES.
- [ ] Personuppgifter får endast behandlas inom EU/EES samt överföras till och behandlas i angivet tredje land. 

## Underbiträden
I detta avsnitt förtecknas underbiträden som har godkänts av den personuppgiftsansvarige. Enligt punkt 9.6 är personuppgiftsbiträdet skyldigt att hålla en vid varje tidpunkt aktuell förteckning över underbiträden som anlitas.

**Underbiträde:**
- Namn: Hetzner
- Organisationsnummer: DE 812871812
- Bistår personuppgiftsbiträdet med följande: Lagring och hosting
- Behandling sker i (land): Finland


# Signatur

**På personuppgiftsbiträdets vägnar:**
- Namn (fullständigt):
- Befattning:
- Ort och datum:
- Namnteckning


............................................................


**På den personuppgiftsansvariges vägnar:**
- Namn (fullständigt):
- Befattning:
- Ort och datum:
- Namnteckning


............................................................
