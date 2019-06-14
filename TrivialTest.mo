model TrivialTest

  parameter Real outVal = 3.0;
  Modelica.Blocks.Interfaces.RealOutput y annotation(
    Placement(visible = true, transformation(origin = {106, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {106, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
  y = outVal;
annotation(
    uses(Modelica(version = "3.2.3")));
end TrivialTestERROR;
