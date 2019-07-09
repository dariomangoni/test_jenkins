within ;
package MyModelicaLibrary "MyModelicaLibrary"
  import SI = Modelica.SIunits;

  annotation (
    Protection(
      showDiagram=true,
      showText=true,
      showVariables=true,
      showDiagnostics=true,
      showStatistics=true,
      allowDuplicate=true),
    preferredView="info",
    version="0.1.0",
    versionDate="2017-11-01",
    versionBuild=1,
    dateModified="2018-01-01",
    uses(Modelica(version = "3.2.3")),
    Documentation(info="<html>
      <p>MyModelicaLibrary documentation</p>
      </html>"));
end MyModelicaLibrary;
