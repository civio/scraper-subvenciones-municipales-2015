**AVISO:** El código está un poco manga por hombro, se hizo contrareloj y tomando bastantes atajos. Pero los datos de los CSV son correctos.

Artículo relacionado: [El PP pierde cinco millones de subvención pública para sufragar la campaña electoral](http://elboenuestrodecadadia.com/2015/05/25/el-pp-pierde-cinco-millones-de-subvencion-publica-para-sufragar-la-campana-electoral/).

Ficheros auxiliares:

* `pobmun14.csv`: padrón municipal a 1 de Enero de 2014. Generado a partir del [fichero XLS del INE](http://www.ine.es/dynt3/inebase/es/index.html?padre=517&dh=1), enriquecido con el código de comunidad autónoma.

* `MOLO99_PARTIDOS_43.csv`: listado de partidos presentes en las elecciones, es uno de los [ficheros usados](http://d35cmun12015p4135.edgesuite.net/99apps/descargasGEN.htm) por la aplicación móvil oficial (gracias a [Javier Cuevas](http://twitter.com/javier_dev) por la pista).

Scripts:

* `fetch.rb`: descarga todos las páginas de datos municipales del portal oficial de [Elecciones Locales 2015](http://resultadoslocales2015.interior.es/).

* `parse.rb`: parsea todos las páginas previamente descargadas, extrayendo los datos de cada municipio (en `town_data.csv`) y los votos de cada candidatura (en `party_data.csv`).

* `calculate.rb`: calcula la subvención asignada a un partido electoral dado. Por ejemplo, para el PP:

        $ ruby calculate.rb 4253

    La lista de códigos de las principales candidaturas está disponible dentro de `calculate.rb`.
