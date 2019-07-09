within MyModelicaLibrary;

package MyPackage "MyPackage"
  model MyModel
    extends MyPartialModel;
    input Real inVal;
    output Real outVal;
  equation
    outVal = inVal + offset;
  end MyModel;

  partial model MyPartialModel
    parameter Real offset = 1.5;
  end MyPartialModel;

  model MyExperiment
    MyModel myModel;
    output Real expOutVal;
  equation
    myModel.inVal = time;
    myModel.outVal = expOutVal;
    annotation(
      experiment(StartTime = 0, StopTime = 1, Tolerance = 1e-06, Interval = 0.01));
  end MyExperiment;

    model MyExperimentBroken
    MyModel myModel;
    output Real expOutVal;
    Real valRandom;
  equation
    myModel.inVal = time;
    myModel.outVal = expOutVal;
    annotation(
      experiment(StartTime = 0, StopTime = 1, Tolerance = 1e-06, Interval = 0.01));
  end MyExperimentBroken;

end MyPackage;
