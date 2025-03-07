%% Run Stoch Models
% =========================================================================
% Author: Matthew Blomquist
%
% Revised code from Colin Smith:
% https://github.com/opensim-jam-org/jam-resources/tree/main/matlab
%
% Purpose: To create and run models with stochastic parameters
%
% Output: Creates 1) executables to run forward simulations and
%   2) stochastic models with altered parameters
%
% Other .m files required:
%   createStochModels.m
%   createStochMalalignMdl.m
%
% Revision history:
%   v1      11-27-2022      First commit (MBB)
%   v2      03-28-2023      Update code for local or HT (MBB)
%
%==========================================================================
clear ; close all ; clc ;

import org.opensim.modeling.*
Logger.setLevelString( 'Info' ) ;

%% ======================= Specify Settings ===========================
% Look through this entire section to change parameters to whatever you
% wish to run. You shouldn't have to change anything other than this
% section. This entire section is creating a structure full of parameters
% to create the models and the files to run simulations
% =====================================================================

% ------------------------------------------------------------------------
% -------------------------- SPECIFY LOCAL VS HT -------------------------
% ------------------------------------------------------------------------

% Specify whether to run locally or whether you will run the models on the
% high-throughput grid
% Options: 'local' or 'HT'
Params.localOrHT = 'local' ;

% Set base name of output folder where models, exectuables, and inputs
% should be created
% I would do it outside of this folder because it's too many files
% for git to track. I usually create them in a folder on my
% desktop, but another folder in documents works as well
Params.baseOutDir = 'C:\Users\mbb201\Desktop\htcTKArelease\localTest' ;
% Also specify which study ID for BAM lab work (not too important,
% but this is what some files will have for a prefix in their name)
Params.studyId = 'bam014' ;

% ------------------------------------------------------------------------
% ----------------------- SPECIFY MODEL PARAMETERS -----------------------
% ------------------------------------------------------------------------

% Copy models from another folder Yes or No
%   If 'Yes', specify which folder to copy models from. This will
%   enable you to reuse models already created. For example, if you ran
%   some laxity test on a given model set, but later decided you wanted to
%   run more, then you can set this to 'Yes' to use the same model set
copyModelsYesNo = 'No' ;
switch copyModelsYesNo
    case 'Yes'
        % Specify the folder with the models. If you are saving the data in
        % the same folder as Params.baseOutDir, then use this line:
        %   fldWithModels = Params.baseOutDir
        % Otherwise, specify which folder to copy from
        fldWithModels = 'ADD PATH HERE' ;
end

% Number of models to create and run
Params.numModels = 1 ;

% Base model to use. Options are in lenhart2015 folder
%   Current options =
%       'lenhart2015' (intact model)
%       'lenhart2015_implant' (TKA model - implants and no ACL or MCLd)
%       'lenhart2015_BCRTKA' (BCR-TKA model - implants with ACL and MCLd)
%       'lenhart2015_UKA' (for Sarah's ISTA abstract)
Params.baseMdl = 'lenhart2015_UKA' ;

% Names of ligaments to change
%   Options: 'allLigs' to change all the ligaments in the model
%                           OR
%     [cell array with each ligament you want to change]
%       'MCLd' , 'MCLs', 'MCLp', 'ACLpl' , 'ACLam' , 'LCL', 'ITB', 'PFL',
%       'pCAP', 'PCLpm', 'PCLal', 'PT', 'lPFL', 'mPFL'
Params.ligNamesToChange = 'allLigs' ;

% Ligament properties to change [cell array]
%   Options: 'linear_stiffness', 'slack_length'
Params.ligPropsToChange = { 'linear_stiffness' , 'slack_length' } ;

% TODO: ADD ABILITY TO CHANGE CARTILAGE WEAR AND ADD OSTEOPHYTES

% Probability distribution type [cell array for each ligPropsToChange]
%   Options: 'normal' , 'uniform'
Params.probDistType = { 'normal' , 'normal' } ;

% Probability distribution reference [cell array for each ligPropsToChange]
%   Options: 'relativePercent' , 'relativeAbs' , 'absolute'
Params.probDistRef = { 'relativePercent' , 'relativePercent' } ;

% Probability distribution parameters (in percent change from baseline model)
%  [cell array for each ligPropsToChange]
%   For 'normal': [ <mean> , <std> ]
%       Example: [ 0, 0.3 ] = mean of 0% change (same as baseline model)
%       with a standard deviation of 30% from the baseline model
%   For 'uniform': [ <lower_limit> , <upper_limit> ]
%       Example: [ -0.2, 0.2 ] = limits of distribution are -20 to 20% of
%       the baseline model value
Params.probDistParams = { [ 0 , 0.25 ] , [ 0 , 0.02 ] } ;

% ------------------------------------------------------------------------
% --------------------- SPECIFY IMPLANT PARAMETERS -----------------------
% ------------------------------------------------------------------------

% Only need to specify implant parameters if the model is
% lenhart2015_implant
switch Params.baseMdl
    case { 'lenhart2015_implant' , 'lenhart2015_BCRTKA' }

        % Femur and tibia implant names
        Params.femImplant = 'lenhart2015-R-femur-implant.stl' ;
        Params.tibImplant = 'lenhart2015-R-tibia-implant.stl' ;

        % Directory with implant files
        Params.implantDir = fullfile( pwd , 'lenhart2015' , 'Geometry' ) ;

        % Probability distribution type for the implants
        %   Options: 'normal' , 'uniform'
        Params.distType = 'uniform' ;

        % Specify lower and upper limits (if uniform) or mean and std (if
        % normal) for femur and tibia Varus-valgus and internal-external
        % rotation of implants. Comment out the sections if you don't want
        % to malalign in that degree of freedom
        % NOTE: All values in deg
        % Medial overstuff
        %   Femur (VV): [ 0 , 2 ], (IE): [ -2 , 0 ]
        %   Tibia (VV): [ -2 , 0 ]
        % Lateral overstuff
        %   Femur (VV): [ -2 , 0 ], (IE): [ 0 , 2 ]
        %   Tibia (VV): [ 0 , 2 ]
        % Tibial slope changes
        %   Negative values for larger tibial slope changes: [ -10 , 0 ]

end

% This section is to specify separate medial and lateral tibial surfaces
switch Params.baseMdl
    case { 'lenhart2015_SarahISTA_PCL' , 'lenhart2015_SarahISTA_noPCL' }
        % Directory with implant files
        Params.implantDir = fullfile( pwd , 'lenhart2015' , 'Geometry' ) ;

        % Femur and tibia implant names
        Params.femImplant = 'lenhart2015-R-femur-implant.stl' ;
        Params.tibImplantMedial = 'lenhart2015-R-tibia-implant-medial.stl' ;
        Params.tibImplantLateral = 'lenhart2015-R-tibia-implant-lateral.stl' ;

    case 'lenhart2015_UKA'
        % Directory with implant files
        Params.implantDir = fullfile( pwd , 'lenhart2015' , 'Geometry' ) ;

        % Femur and tibia implant names
        Params.femImplantMedial = 'femur_implant_medial.stl' ;
        Params.femCartilageLateral = 'femur_cartilage_lateral.stl' ;
        Params.tibImplantMedial = 'tibia_implant_medial_04.stl' ;
        Params.tibCartilageLateral = 'tibia_cartilage_lateral.stl' ;
end


% ------------------------------------------------------------------------
% -------------------- SPECIFY SIMULATION PARAMETERS ---------------------
% ------------------------------------------------------------------------

% Specify forward simulation test(s) to run [cell array]
%   For Laxity Tests, options are:
%       Anterior: 'ant'
%       Posterior: 'post'
%       Varus: 'var'
%       Valgus: 'val'
%       Internal Rotation: 'ir'
%       External Rotation: 'er'
%       Compression: 'comp'
%       Distraction: 'dist'
%   For Passive Flexion, options are:
%       Passive: 'flex'
%   For Combined loading tests:
%       Add DOFs separated by hyphen:
%       Example: compression and anterior load: ant-comp
Params.testDOFs = { 'flex' } ;

% Specify flexion angle(s) of knee during each simulation [cell array]
%   For passive flexion, specify the end flexion angle (starts at 0)
%   Each testDOF will be run at each flexion angle (so the total number of
%   simulations will be length(testDOFs) * length( kneeFlexAngles )
Params.kneeFlexAngles = { 90 } ;

% Specify external load(s) applied, one for each testDOFs [cell array]
%   Put 0 if passive flexion test
%   Add array for combined loading (e.g., for posterior and compression,
%       "{ [ 350 , 3000 ] }" for 350N of posterior and 3000N of compression
%   Keep these number positive
Params.externalLoads = { 0 } ;

%% ============ Checks to make sure Params is set up correctly ============
% Throw an error before running code if something in Params is not set up
% correctly
% =========================================================================

if length( Params.ligPropsToChange ) ~= length( Params.probDistType )
    error( 'Error: ligPropsToChange needs to be the same length as probDistType' )
elseif length( Params.ligPropsToChange ) ~= length( Params.probDistRef )
    error( 'Error: ligPropsToChange needs to be the same length as probDistRef' )
elseif length( Params.ligPropsToChange ) ~= length( Params.probDistParams )
    error( 'Error: ligPropsToChange needs to be the same length as probDistParams' )
elseif length( Params.testDOFs ) ~= length( Params.externalLoads )
    error( 'Error: testDOFs needs to be the same length as externalLoads' )
end

%% ======================== Compute Trial Name ===========================
% Computes the trial name(s) that will be used for creating executables and
% input files. Puts it in a cell array
% ========================================================================

% For passive flexion:
%   1) flexion, 2) passive, 3) start flexion, 4) end flexion
%   Ex: 'flex_passive_0_90'
% For laxity tests:
%   1) laxity, 2) degree of freedom, 3) force applied, 4) flexion angle
%   Ex: 'lax_var_frc10_25'

Params.trialNames = { } ; % initialize
trialCounter = 1 ; % counter for loop
for iDOF = 1 : length( Params.testDOFs )
    if isequal( Params.testDOFs{iDOF} , 'flex' ) % if passive flexion test
        for iAng = 1 : length( Params.kneeFlexAngles ) % loop through flexion angles
            Params.trialNames{ trialCounter } = ...
                [ 'flex_passive_0_' , num2str( Params.kneeFlexAngles{iAng} ) ] ;
            trialCounter = trialCounter + 1 ;
        end
    elseif contains( Params.testDOFs{iDOF} , '-' ) % if combined loading
        for iAng = 1 : length( Params.kneeFlexAngles ) % loop through flexion angles
            Params.trialNames{ trialCounter } = ...
                [ 'lax_' , Params.testDOFs{iDOF} , '_frc' , num2str( Params.externalLoads{iDOF}(1) ) , '-' , num2str( Params.externalLoads{iDOF}(2) ) , '_' , num2str( Params.kneeFlexAngles{iAng} ) ] ;
            trialCounter = trialCounter + 1 ;
        end
    else % if laxity test
        for iAng = 1 : length( Params.kneeFlexAngles ) % loop through flexion angles
            Params.trialNames{ trialCounter } = ...
                [ 'lax_' , Params.testDOFs{iDOF} , '_frc' , num2str( Params.externalLoads{iDOF} ) , '_' , num2str( Params.kneeFlexAngles{iAng} ) ] ;
            trialCounter = trialCounter + 1 ;
        end
    
    end
end

Params.numTrials = length( Params.trialNames ) ;

clear trialCounter iDOF iAng

%% ========================== Set up folders =============================
% Sets up folders to put models and executables
% ========================================================================
Params.baseMdlFile = fullfile( pwd , 'lenhart2015' , [ Params.baseMdl , '.osim' ] ) ;

switch Params.localOrHT
    case 'local'
        % Check if inputs, stochModels, and results directories exist. If
        % they don't, create them.
        % baseOutDir
        if ~exist( Params.baseOutDir , 'dir' )
            mkdir( Params.baseOutDir )
        end
        % inputs
        if ~exist( fullfile( Params.baseOutDir , 'inputs' ) , 'dir' )
            if isequal( copyModelsYesNo , 'Yes' )
                copyfile( fullfile( fldWithModels , 'inputs' ) , fullfile( Params.baseOutDir , 'inputs' ) )
            else
                mkdir( fullfile( Params.baseOutDir , 'inputs' ) )
            end
        end
        % stochModels
        if ~exist( fullfile( Params.baseOutDir , 'stochModels' ) , 'dir' )
            mkdir( fullfile( Params.baseOutDir , 'stochModels' ) )
            copyfile( 'lenhart2015\Geometry' , fullfile( Params.baseOutDir , 'stochModels\Geometry' ) )
        end
        % results
        if ~exist( fullfile( Params.baseOutDir , 'results' ) , 'dir' )
            mkdir( fullfile( Params.baseOutDir , 'results' ) )
        end
    case 'HT'
        % Check to see if Params.baseOutDir exists. If it doesn't, then
        % create subfolders to be able to use on the high throughput grid
        % baseOutDir
        if ~exist( Params.baseOutDir , 'dir' )
            mkdir( Params.baseOutDir )
        end
        % inputs
        if ~exist( fullfile( Params.baseOutDir , 'input' ) , 'dir' )
            if isequal( copyModelsYesNo , 'Yes' )
                copyfile( fullfile( fldWithModels , 'input' ) , fullfile( Params.baseOutDir , 'input' ) )
                for iMdl = 1 : Params.numModels
                    delete( fullfile( Params.baseOutDir , 'input' , num2str(iMdl-1) , '*.stl' ) )
                end
            else
                mkdir( fullfile( Params.baseOutDir , 'input' ) )
                for iMdl = 1 : Params.numModels
                    mkdir( fullfile( Params.baseOutDir , 'input' , num2str(iMdl-1) ) )
                end
            end
        end
        % shared folders and results folders
        for iDOF = 1 : length( Params.testDOFs )
            if ~exist( fullfile( Params.baseOutDir , Params.testDOFs{iDOF} ) , 'dir' )
                mkdir( fullfile( Params.baseOutDir , Params.testDOFs{iDOF} ) )
                copyfile( 'sharedFilesForHT\' , fullfile( Params.baseOutDir , Params.testDOFs{iDOF} , 'shared' ) )
                mkdir( fullfile( Params.baseOutDir , Params.testDOFs{iDOF} ) , 'results' )
                for iMdl = 1 : Params.numModels
                    mkdir( fullfile( Params.baseOutDir , Params.testDOFs{iDOF} , 'results' , num2str(iMdl-1) ) )
                end
            end
        end
end

%% ======================== Create Stoch Models ==========================
% Create stochastic models and (if applicable) malaligned implants
% ========================================================================

switch Params.baseMdl
    case { 'lenhart2015_implant' , 'lenhart2015_BCRTKA' }

        switch Params.localOrHT
            case 'local'
                doneMsg = createStochMalalignMdl( Params ) ;

            case 'HT'
                if isfield( Params , 'femRot' ) || isfield( Params , 'tibRot' )
                    % If rotating either the femur or tibia, then run
                    % createStochMalalignMdl
                    doneMsg = createStochMalalignMdl( Params ) ;
                else
                    % If rotating neither implant, then copy the implant STLs to be in
                    % the shared directory
                    for iDOF = 1 : length( Params.testDOFs )
                        copyfile( fullfile( Params.implantDir , Params.femImplant ) , ...
                            fullfile( Params.baseOutDir , Params.testDOFs{iDOF} , 'shared' , 'lenhart2015-R-femur-implant.stl' ) )
                        copyfile( fullfile( Params.implantDir , Params.tibImplant ) , ...
                            fullfile( Params.baseOutDir , Params.testDOFs{iDOF} , 'shared' , 'lenhart2015-R-tibia-implant.stl') )
                    end
                end
        end

    case { 'lenhart2015_SarahISTA_PCL' , 'lenhart2015_SarahISTA_noPCL' }

        switch Params.localOrHT                
            case 'local'
                copyfile( fullfile( Params.implantDir , Params.femImplant ) , ...
                    fullfile( Params.baseOutDir , 'stochModels' , 'Geometry' , 'lenhart2015-R-femur-implant.stl' ) )
                copyfile( fullfile( Params.implantDir , Params.tibImplantMedial ) , ...
                    fullfile( Params.baseOutDir , 'stochModels' , 'Geometry' , 'lenhart2015-R-tibia-implant-medial.stl') )
                copyfile( fullfile( Params.implantDir , Params.tibImplantLateral ) , ...
                    fullfile( Params.baseOutDir , 'stochModels' , 'Geometry' , 'lenhart2015-R-tibia-implant-lateral.stl') )

            case 'HT'
                for iDOF = 1 : length( Params.testDOFs )
                    copyfile( fullfile( Params.implantDir , Params.femImplant ) , ...
                        fullfile( Params.baseOutDir , Params.testDOFs{iDOF} , 'shared' , 'lenhart2015-R-femur-implant.stl' ) )
                    copyfile( fullfile( Params.implantDir , Params.tibImplantMedial ) , ...
                        fullfile( Params.baseOutDir , Params.testDOFs{iDOF} , 'shared' , 'lenhart2015-R-tibia-implant-medial.stl') )
                    copyfile( fullfile( Params.implantDir , Params.tibImplantLateral ) , ...
                        fullfile( Params.baseOutDir , Params.testDOFs{iDOF} , 'shared' , 'lenhart2015-R-tibia-implant-lateral.stl') )
                end
        end

    case 'lenhart2015_UKA'

        switch Params.localOrHT                
            case 'local'
                copyfile( fullfile( Params.implantDir , Params.femImplantMedial ) , ...
                    fullfile( Params.baseOutDir , 'stochModels' , 'Geometry' , 'lenhart2015-R-femur-implant-medial.stl' ) )
                copyfile( fullfile( Params.implantDir , Params.femCartilageLateral ) , ...
                    fullfile( Params.baseOutDir , 'stochModels' , 'Geometry' , 'lenhart2015-R-femur-cartilage-lateral.stl' ) )
                copyfile( fullfile( Params.implantDir , Params.tibImplantMedial ) , ...
                    fullfile( Params.baseOutDir , 'stochModels' , 'Geometry' , 'lenhart2015-R-tibia-implant-medial.stl') )
                copyfile( fullfile( Params.implantDir , Params.tibCartilageLateral ) , ...
                    fullfile( Params.baseOutDir , 'stochModels' , 'Geometry' , 'lenhart2015-R-tibia-cartilage-lateral.stl') )

            case 'HT'
                for iDOF = 1 : length( Params.testDOFs )
                    copyfile( fullfile( Params.implantDir , Params.femImplant ) , ...
                        fullfile( Params.baseOutDir , Params.testDOFs{iDOF} , 'shared' , 'lenhart2015-R-femur-implant-medial.stl' ) )
                    copyfile( fullfile( Params.implantDir , Params.femImplant ) , ...
                        fullfile( Params.baseOutDir , Params.testDOFs{iDOF} , 'shared' , 'lenhart2015-R-femur-cartilage-lateral.stl' ) )
                    copyfile( fullfile( Params.implantDir , Params.tibImplantMedial ) , ...
                        fullfile( Params.baseOutDir , Params.testDOFs{iDOF} , 'shared' , 'lenhart2015-R-tibia-implant-medial.stl') )
                    copyfile( fullfile( Params.implantDir , Params.tibImplantLateral ) , ...
                        fullfile( Params.baseOutDir , Params.testDOFs{iDOF} , 'shared' , 'lenhart2015-R-tibia-cartilage-lateral.stl') )
                end
        end
end


% Run createStochMalalignMdl code if running implant code
if isequal( copyModelsYesNo , 'No' )

    % Create Stochastic models
    StochMdlParams = createStochModels( Params ) ;

end

% outMsg = changeWrappingSurface( Params ) ;

%% =================== Define Simulation Time Points =====================
% Define the duration of each portion of the simulation (flexion, settle,
% load, etc)
% ========================================================================

% Simulation consists of three to five phases:
% All simulations consist of:
%   Settle : allow knee to settle into equilbrium
%   Flex   : period of knee flexion
%   Settle : allow knee to settle into equilbrium
% If laxity test, add these two:
%   Force  : ramp up the desired external force
%   Settle : hold force constant and allow knee to settle into equilbrium

% Time step for simulation
timeStep = 0.01;

% Initialize
numPhases = zeros( Params.numTrials , 1 ) ;
time = cell( Params.numTrials , 1 ) ;
timePoints = cell( Params.numTrials , 1 ) ;
numSteps = zeros( Params.numTrials , 1 ) ;

% Loop through each test
for iTrial = 1 : Params.numTrials

    % Define temporary trial name to extract temporary DOF
    tempTrialName = Params.trialNames{ iTrial } ;
    splitName = split( tempTrialName , '_' ) ;
    if isequal( splitName{1} , 'flex' )
        tempDOF = 'flex' ;
    else
        tempDOF = splitName{2} ;
    end

    if strcmp( tempDOF , 'flex' ) % passive flexion
        % Specify duration of each phase
        phaseDurations = [ ...
            0.5 ... % Settle 1 Duration
            1.0 ... % Flex Duration
            0.5 ... % Settle 2 Duration
            ] ;
    else % laxity test
        % Specify duration of each phase
        phaseDurations = [ ...
            0.5 ... % Settle 1 Duration
            1.0 ... % Flex Duration
            0.5 ... % Settle 2 Duration
            1.0 ... % External Force Duration
            0.5 ... % Settle 3 Duration
            ] ;
    end

    % Number of phases
    numPhases(iTrial) = length( phaseDurations ) ;

    % Total duration of simulation
    simDuration = sum( phaseDurations ) ;

    % Time array of simulation
    time{iTrial} = 0 : timeStep : simDuration ;

    % Compute starting time points for each phase
    timePoints{iTrial} = zeros( 1 , numPhases(iTrial) + 1 ) ; % initialize array before for loop
    for iTimePt = 1 : numPhases(iTrial)
        timePoints{iTrial}( 1 , iTimePt+1 ) = sum( phaseDurations( 1 : iTimePt ) ) ;
    end

    % Compute the number of steps in the simulation
    numSteps(iTrial) = length( time{iTrial} ) ;

end

%% ================ Create Prescribed Coordinates File ===================
% The Prescribed Coordinates file sets the hip, knee, and pelvis flexion
% angles to their prescibed values
% ========================================================================

% For passive flexion:
%   1) flexion, 2) passive, 3) start flexion, 4) end flexion
%   Ex: 'flex_passive_0_90'
% For laxity tests:
%   1) laxity, 2) degree of freedom, 3) force applied, 4) flexion angle
%   Ex: 'lax_var_frc10_25'

% Hip flexion angle
hipFlexAngle = 0 ;

% Pelvis Tilt
pelvisTilt = 90 ; % 0 = standing, 90 = supine

% Loop through each test
for iTrial = 1 : Params.numTrials

    % Define temporary trial name to extract temporary DOF and angle
    tempTrialName = Params.trialNames{ iTrial } ;
    splitName = split( tempTrialName , '_' ) ;
    if isequal( splitName{1} , 'flex' )
        tempDOF = 'flex' ;
    else
        tempDOF = splitName{2} ;
    end
    tempAng = str2double( splitName{4} ) ;

    % .sto File Name
    prescribedCoordinatesFileName = ...
        [ 'prescribed_coordinates_' , tempTrialName , '.sto' ] ;

    coord_data.time = time{iTrial} ;

    % Knee data
    kneeFlexData = [ zeros( 1  , 2 ) , ones( 1 , numPhases(iTrial)-1 ) * tempAng ] ;
    smoothKneeFlexData = interp1( timePoints{iTrial} , kneeFlexData , time{iTrial} , 'pchip' ) ;
    coord_data.knee_flex_r = smoothKneeFlexData' ;

    % Hip data
    hipFlexData = [ zeros( 1  , 2 ) , ones( 1 , numPhases(iTrial)-1 ) * hipFlexAngle ] ;
    smoothHipFlexData = interp1( timePoints{iTrial} , hipFlexData , time{iTrial} , 'pchip' ) ;
    coord_data.hip_flex_r = smoothHipFlexData' ;

    % Pelvis data
    coord_data.pelvis_tilt = ones( length(time{iTrial}) , 1 ) * pelvisTilt ;

    % Function distributed in OpenSim Resources\Code\Matlab\Utilities
    coord_table = osimTableFromStruct( coord_data ) ;

    switch Params.localOrHT
        case 'local'
            outDir = fullfile( Params.baseOutDir , 'inputs' ) ;
        case 'HT'
            outDir = fullfile( Params.baseOutDir , tempDOF , 'shared' ) ;
    end

    % Write file
    STOFileAdapter.write( coord_table , fullfile( outDir , prescribedCoordinatesFileName ) ) ;

end


%% ==================== Create External Load Files =======================
% The external load files are to specify where, how much, and in which
% direction external loads should be applied during the simulation.
% ========================================================================

% Loop through each test
for iTrial = 1 : Params.numTrials

    % Define temporary trial name to extract temporary DOF
    tempTrialName = Params.trialNames{ iTrial } ;
    splitName = split( tempTrialName , '_' ) ;
    if isequal( splitName{1} , 'flex' )
        testDOFs = 'flex' ;
    else
        testDOFs = strsplit( splitName{2} , '-' ) ;
    end

    % Create external loads files if it is a laxity test (i.e., not a
    %   passive flexion test)
    if ~strcmp( testDOFs , 'flex' ) % if not passive flexion test

        % External load magnitude(s)
        tempLoads = str2double( split( splitName{3}(4:end) , '-' ) ) ;

        % .sto and .xml File Name
        externalLoadsSto = [ 'external_loads_' , tempTrialName , '.sto' ] ;
        externalLoadsXml = [ 'external_loads_' , tempTrialName , '.xml' ] ;

        % Construct arrays for sto file based on
        loadData.time = time{iTrial} ;
        tempNumSteps = numSteps(iTrial) ;

        % Initialize
        loadData.tibia_proximal_r_force_vx = zeros( tempNumSteps , 1 ) ;
        loadData.tibia_proximal_r_force_vy = zeros( tempNumSteps , 1 ) ;
        loadData.tibia_proximal_r_force_vz = zeros( tempNumSteps , 1 ) ;
        loadData.tibia_proximal_r_force_px = zeros( tempNumSteps , 1 ) ;
        loadData.tibia_proximal_r_force_py = zeros( tempNumSteps , 1 ) ;
        loadData.tibia_proximal_r_force_pz = zeros( tempNumSteps , 1 ) ;
        loadData.tibia_proximal_r_torque_x = zeros( tempNumSteps , 1 ) ;
        loadData.tibia_proximal_r_torque_y = zeros( tempNumSteps , 1 ) ;
        loadData.tibia_proximal_r_torque_z = zeros( tempNumSteps , 1 ) ;

        for iDOF = 1 : length( testDOFs )

            tempDOF = testDOFs{ iDOF } ;

            % Define positive and negative directions
            switch tempDOF
                case { 'ant', 'ir', 'val', 'comp' }
                    loadSign = 1 ;
                case { 'post', 'er', 'var', 'dist' }
                    loadSign = -1 ;
            end

            % Define location and magnitude of load based on testDof and externalLoad
            switch tempDOF
                case { 'ant' , 'post' }
                    loadPointHeight = -0.1 ; % Apply at the tibial tuberosity height similar to KT-1000 test
                    loadMagnitude = tempLoads(iDOF) * loadSign ;
                case { 'var' , 'val' }
                    loadPointHeight = -0.3 ; % Apply near ankle similiar to coronal laxity test
                    loadMagnitude = tempLoads(iDOF) / abs(loadPointHeight) * loadSign ; % Moment, so account for moment arm
                case { 'ir' , 'er' , 'dist' , 'comp' }
                    loadMagnitude = tempLoads(iDOF) * loadSign ; % Apply at location = 0
            end

            % Create external load array
            loadArray = [ zeros( 1 , 4 ) , loadMagnitude , loadMagnitude ] ;
            smoothLoadArray = interp1( timePoints{iTrial} , loadArray , time{iTrial} , 'pchip' );

            % Construct arrays for sto file based on
            switch tempDOF
                case { 'ant', 'post' }
                    % Applied load in x-direction distal to knee
                    loadData.tibia_proximal_r_force_vx = smoothLoadArray' ;
                    loadData.tibia_proximal_r_force_py = ones( tempNumSteps , 1 ) * loadPointHeight ;
                case { 'var', 'val' }
                    % Applied load in z-direction at ankle
                    loadData.tibia_proximal_r_force_vz = smoothLoadArray' ;
                    loadData.tibia_proximal_r_force_py = ones( tempNumSteps , 1 ) * loadPointHeight ;
                case { 'ir', 'er' }
                    % Applied torque about y-direction
                    loadData.tibia_proximal_r_torque_y = smoothLoadArray' ;
                case { 'comp', 'dist' }
                    % Applied force about y-direction
                    loadData.tibia_proximal_r_force_vy = smoothLoadArray' ;
            end

        end

        % Function distributed in OpenSim Resources\Code\Matlab\Utilities
        loadTable = osimTableFromStruct( loadData ) ;
        loadTable.addTableMetaDataString( 'header' , [ tempTrialName , ' External Load' ] )

        switch Params.localOrHT
            case 'local'
                outDir = fullfile( Params.baseOutDir , 'inputs' ) ;
            case 'HT'
                outDir = fullfile( Params.baseOutDir , splitName{2} , 'shared' ) ;
        end
        STOFileAdapter.write( loadTable , fullfile( outDir , externalLoadsSto ) );

        % Construct External Force
        extForce = ExternalForce() ;
        extForce.setName( [ tempTrialName , '_load' ] );
        extForce.set_applied_to_body( 'tibia_proximal_r' );
        extForce.set_force_expressed_in_body( 'tibia_proximal_r' );
        extForce.set_point_expressed_in_body( 'tibia_proximal_r' );
        extForce.set_force_identifier( 'tibia_proximal_r_force_v' );
        extForce.set_point_identifier( 'tibia_proximal_r_force_p' );
        extForce.set_torque_identifier( 'tibia_proximal_r_torque_' );

        % Construct External Loads
        extLoads = ExternalLoads() ;
        extLoads.setDataFileName( externalLoadsSto  ) ;
        extLoads.cloneAndAppend( extForce ) ;
        extLoads.print( fullfile( outDir , externalLoadsXml ) ) ;
    end
end
%% ====== Create Forsim Settings Files And Run/Create Linux Files ========
% Create the forward simulation settings file(s) that specifies how the
% forward simulation should be run, which files it calls on, and where the
% outputs should go.
% Then, for local simulations, run each model under the specified forward
% simulations. For HT simulations, create .sh and .sub files to run on the
% high throughput grid.
% ========================================================================

% Loop through each trial
for iTrial = 1 : Params.numTrials

    % Define temporary trial name to extract temporary DOF
    tempTrialName = Params.trialNames{ iTrial } ;
    splitName = split( tempTrialName , '_' ) ;
    if isequal( splitName{1} , 'flex' )
        tempDOF = 'flex' ;
    else
        tempDOF = splitName{2} ;
    end

    switch Params.localOrHT

        % ----------------------------------------------------------------
        % ---------------------------- LOCAL -----------------------------
        % ----------------------------------------------------------------

        case 'local'

            % Loop through each Model to create forsim_settings and run the model
            for iMdl = 1 : Params.numModels

                % If implant model, then switch out stoch implants so that
                % lenhart model reads the correct one
                switch Params.baseMdl
                    case { 'lenhart2015_implant' , 'lenhart2015_BCRTKA' }
                        tempStochFemName = [ Params.femImplant(1:end-4) , '_' , num2str( iMdl ) , '.stl' ] ;
                        tempStochTibName = [ Params.tibImplant(1:end-4) , '_' , num2str( iMdl ) , '.stl' ] ;

                        movefile( fullfile( Params.baseOutDir , 'stochModels' , 'Geometry' , tempStochFemName ) , ...
                            fullfile( Params.baseOutDir , 'stochModels' , 'Geometry' , Params.femImplant ) )
                        movefile( fullfile( Params.baseOutDir , 'stochModels' , 'Geometry' , tempStochTibName ) , ...
                            fullfile( Params.baseOutDir , 'stochModels' , 'Geometry' , Params.tibImplant ) )
                end

                % Specify settings
                forsimSettingsFileName = [ 'forsim_settings_' , tempTrialName , '.xml' ] ;
                modelFile = fullfile( Params.baseOutDir , 'stochModels' , [ 'lenhart2015_stoch' , num2str(iMdl) , '.osim' ] ) ;
                forsimResultDir = fullfile( Params.baseOutDir , 'results' ) ;
                resultsBasename = [ tempTrialName , '_' , num2str( iMdl ) ] ;

                % Set the integrator accuracy
                %   Choose value between speed (1e-2) vs accuracy (1e-8)
                integratorAccuracy = 1e-3 ;

                % Create ForsimTool
                forsim = ForsimTool() ;

                % Create AnalysisSet
                analysisSet = AnalysisSet() ;

                % Create ForceReporter
                frcReporter = ForceReporter();

                % Set settings
                frcReporter.setName( 'ForceReporter' ) ;
                analysisSet.cloneAndAppend( frcReporter ) ;
                forsim.set_AnalysisSet( analysisSet ) ;
                forsim.set_model_file( modelFile ) ; % location and name of model
                forsim.set_results_directory( forsimResultDir ) ; % location to put results files
                forsim.set_results_file_basename( resultsBasename ) ; % basename of results files
                forsim.set_start_time( -1 ) ; % set to -1 to use data from input files
                forsim.set_stop_time( -1 ) ; % set to -1 to use data from input files
                forsim.set_integrator_accuracy( integratorAccuracy ) ; % accuracy of the solver
                forsim.set_constant_muscle_control( 0.001 ) ; % 0.001 to represent passive state
                forsim.set_report_time_step( 0.01 ) ; % set to decrease output size
                forsim.set_use_activation_dynamics( true ) ; % use activation dynamics
                forsim.set_use_tendon_compliance( false ) ; % use tendon compliance
                forsim.set_use_muscle_physiology( true ) ; % use muscle physiology
                % Set all coordinates to be unconstrained except flexion-extension
                forsim.set_unconstrained_coordinates( 0 , '/jointset/knee_r/knee_add_r' ) ;
                forsim.set_unconstrained_coordinates( 1 , '/jointset/knee_r/knee_rot_r' ) ;
                forsim.set_unconstrained_coordinates( 2 , '/jointset/knee_r/knee_tx_r' ) ;
                forsim.set_unconstrained_coordinates( 3 , '/jointset/knee_r/knee_ty_r' ) ;
                forsim.set_unconstrained_coordinates( 4 , '/jointset/knee_r/knee_tz_r' ) ;
                forsim.set_unconstrained_coordinates( 5 , '/jointset/pf_r/pf_flex_r' ) ;
                forsim.set_unconstrained_coordinates( 6 , '/jointset/pf_r/pf_rot_r' ) ;
                forsim.set_unconstrained_coordinates( 7 , '/jointset/pf_r/pf_tilt_r' ) ;
                forsim.set_unconstrained_coordinates( 8 , '/jointset/pf_r/pf_tx_r' ) ;
                forsim.set_unconstrained_coordinates( 9 , '/jointset/pf_r/pf_ty_r' ) ;
                forsim.set_unconstrained_coordinates( 10 , '/jointset/pf_r/pf_tz_r' ) ;
                forsim.set_prescribed_coordinates_file( fullfile( Params.baseOutDir , 'inputs' , [ 'prescribed_coordinates_' , tempTrialName , '.sto' ] ) ) ;
                if strcmp( tempDOF , 'flex' ) % passive flexion
                    forsim.set_external_loads_file( '' ) ;
                else % laxity test
                    forsim.set_external_loads_file( fullfile( Params.baseOutDir , 'inputs' , [ 'external_loads_' , tempTrialName , '.xml' ] ) ) ;
                end
                forsim.set_use_visualizer( false ) ; % use visualizer while running (true or false)
                forsim.print( fullfile( Params.baseOutDir , 'inputs' , forsimSettingsFileName ) ) ;

                tic % compute time that simulation runs
                disp( [ 'Running Forsim Tool, Model '  , num2str( iMdl ) ] )
                forsim.run() ;
                toc

                % If implant model, then switch back names of implants
                switch Params.baseMdl
                    case { 'lenhart2015_implant' , 'lenhart2015_BCRTKA' }
                        movefile( fullfile( Params.baseOutDir , 'stochModels' , 'Geometry' , Params.femImplant ) , ...
                            fullfile( Params.baseOutDir , 'stochModels' , 'Geometry' , tempStochFemName ) )
                        movefile( fullfile( Params.baseOutDir , 'stochModels' , 'Geometry' , Params.tibImplant ) , ...
                            fullfile( Params.baseOutDir , 'stochModels' , 'Geometry' , tempStochTibName ) )
                end

            end

            % ----------------------------------------------------------------
            % ------------------------------ HT ------------------------------
            % ----------------------------------------------------------------

        case 'HT'

            % Specify settings
            forsimSettingsFileName = [ 'forsim_settings_' , tempTrialName , '.xml' ] ;
            modelFile = './lenhart2015_stoch.osim' ;
            forsimResultDir = './' ;
            resultsBasename = tempTrialName ;

            % Set the integrator accuracy
            %   Choose value between speed (1e-2) vs accuracy (1e-8)
            integratorAccuracy = 1e-3 ;

            % Create ForsimTool
            forsim = ForsimTool() ;

            % Create AnalysisSet
            analysisSet = AnalysisSet() ;

            % Create ForceReporter
            frcReporter = ForceReporter();

            % Set settings
            frcReporter.setName( 'ForceReporter' ) ;
            analysisSet.cloneAndAppend( frcReporter ) ;
            forsim.set_AnalysisSet( analysisSet ) ;
            forsim.set_model_file( modelFile ) ; % location and name of model
            forsim.set_results_directory( forsimResultDir ) ; % location to put results files
            forsim.set_results_file_basename( resultsBasename ) ; % basename of results files
            forsim.set_start_time( -1 ) ; % set to -1 to use data from input files
            forsim.set_stop_time( -1 ) ; % set to -1 to use data from input files
            forsim.set_integrator_accuracy( integratorAccuracy ) ; % accuracy of the solver
            forsim.set_constant_muscle_control( 0.001 ) ; % 0.001 to represent passive state
            forsim.set_report_time_step( 0.1 ) ; % set to decrease output size
            forsim.set_use_activation_dynamics( true ) ; % use activation dynamics
            forsim.set_use_tendon_compliance( false ) ; % use tendon compliance
            forsim.set_use_muscle_physiology( true ) ; % use muscle physiology
            % Set all coordinates to be unconstrained except flexion-extension
            forsim.set_unconstrained_coordinates( 0 , '/jointset/knee_r/knee_add_r' ) ;
            forsim.set_unconstrained_coordinates( 1 , '/jointset/knee_r/knee_rot_r' ) ;
            forsim.set_unconstrained_coordinates( 2 , '/jointset/knee_r/knee_tx_r' ) ;
            forsim.set_unconstrained_coordinates( 3 , '/jointset/knee_r/knee_ty_r' ) ;
            forsim.set_unconstrained_coordinates( 4 , '/jointset/knee_r/knee_tz_r' ) ;
            forsim.set_unconstrained_coordinates( 5 , '/jointset/pf_r/pf_flex_r' ) ;
            forsim.set_unconstrained_coordinates( 6 , '/jointset/pf_r/pf_rot_r' ) ;
            forsim.set_unconstrained_coordinates( 7 , '/jointset/pf_r/pf_tilt_r' ) ;
            forsim.set_unconstrained_coordinates( 8 , '/jointset/pf_r/pf_tx_r' ) ;
            forsim.set_unconstrained_coordinates( 9 , '/jointset/pf_r/pf_ty_r' ) ;
            forsim.set_unconstrained_coordinates( 10 , '/jointset/pf_r/pf_tz_r' ) ;
            forsim.set_prescribed_coordinates_file( [ 'prescribed_coordinates_' , tempTrialName , '.sto' ] ) ;
            if strcmp( tempDOF , 'flex' ) % passive flexion
                forsim.set_external_loads_file( '' ) ;
            else % laxity test
                forsim.set_external_loads_file( [ 'external_loads_' , tempTrialName , '.xml' ] ) ;
            end
            forsim.set_use_visualizer( false ) ; % use visualizer while running (true or false)
            forsim.print( fullfile( Params.baseOutDir , tempDOF , 'shared' , forsimSettingsFileName ) ) ;

    end

end

%% ========== Create Sh and Sub Files if Running on the Grid =============
% Running on linux requires a couple additional files to run called a
% shared file (.sh) and a submit file (.sub). So, if running on the grid,
% create these extra files
% ========================================================================

switch Params.localOrHT
    case 'HT'
        for iDOF = 1 : length( Params.testDOFs )

            Params.tempTestDOF = Params.testDOFs{iDOF} ;

            % ----------------
            % Tar shared files
            % ----------------
            Params.opensimLibTarName = 'opensim-jam.tar.gz' ;
            Params.sharedTarName = 'shared.tar.gz' ;
            Params.sharedDir = fullfile( Params.baseOutDir , Params.tempTestDOF , 'shared' ) ;

            disp( 'Tarring files...' )
            tar( fullfile( Params.sharedDir , Params.sharedTarName ) , '.' , Params.sharedDir )
            disp( [ 'Tar file created in ' , Params.sharedDir ] )

            % Delete rest of contents in shared folder
            sharedDirContents = dir( Params.sharedDir ) ;
            for iFile = 1 : length( sharedDirContents )
                if ~isequal( sharedDirContents(iFile).name , '.' ) && ...
                        ~isequal( sharedDirContents(iFile).name , '..' ) && ...
                        ~isequal( sharedDirContents(iFile).name , Params.sharedTarName )
                    % If not the tar file, the current dir, or upper dir,
                    % then delete the file
                    if sharedDirContents(iFile).isdir
                        rmdir( fullfile( Params.sharedDir , sharedDirContents(iFile).name ) , 's' )
                    else
                        delete( fullfile( Params.sharedDir , sharedDirContents(iFile).name ) )
                    end
                end
            end

            % ----------------
            % Create .sub file
            % ----------------
            Params.date = char( datetime( 'today', 'format', 'yyyy-MM-dd' ) ) ;
            Params.trialDir = fullfile( Params.baseOutDir , Params.tempTestDOF ) ;
            Params.shName = 'runJob.sh' ;
            outMsg = writeHtcSubFile( Params ) ;
            disp( outMsg )

            % ---------------
            % Create .sh file
            % ---------------
            outMsg = writeHtcShFile( Params ) ;
            disp( outMsg )

        end
end