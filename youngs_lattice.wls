#!/usr/bin/env wolframscript

imageFolder = "output";
imageSize = 240 * {4, 3};
exportToPov = False;
exportToPov = True;

Needs["POVRayRender`"];
ConfigurePOVRayRender["POVRayPath" -> "C:\\Program Files\\POV-Ray\\v3.7\\bin\\pvengine64.exe"];

(* 
manual test:

topology = { {} -> {1}, {1} -> {1, 1}, {1} -> {2}, {1, 1} -> {1, 1, 1}, {1, 1} -> {2, 1}, {2} -> {2, 1}, {2} -> {3}, {2, 1} -> {2, 2} }; 
*)

For[semiPerimeter = 2, semiPerimeter <= 10, semiPerimeter ++,
    generations = { {{}} };
    edges = { };

    For[generation = 1, generation <= Length[generations], generation ++,
        newGeneration = {};
        currentGeneration = generations[[generation]];

        For[objectId = 1, objectId <= Length[currentGeneration], objectId++,
            object = currentGeneration[[objectId]];

            For[position = 1, position <= Length[object], position++,
                If[position == 1,
                    If[object[[position]] + 1 + Length[object] <= semiPerimeter + 1,
                        newObject = object;
                        newObject[[position]] += 1; 
                        AppendTo[newGeneration, newObject];
                        AppendTo[edges, object -> newObject]
                    ],
                    (* position > 1 *)
                    If[object[[position]] < object[[position - 1]],
                        newObject = object;
                        newObject[[position]] += 1; 
                        AppendTo[newGeneration, newObject];
                        AppendTo[edges, object -> newObject]
                    ]
                ];
            ];

            If[If[Length[object] == 0, 0, object[[1]]] + Length[object] + 1 <= semiPerimeter + 1,
                newObject = Append[object, 1];
                AppendTo[newGeneration, newObject];
                AppendTo[edges, object -> newObject]
            ];
        ];

        newGeneration = Union[newGeneration];
        If[Length[newGeneration] > 0, 
            AppendTo[generations, newGeneration];
        ];
    ];

    Print[semiPerimeter];
    nodes = Flatten[generations, 1];
    Print[Length[nodes]];
    Print[Length[edges]];

    edgeSize = 0.5 / semiPerimeter ^ (0.65);
    nodeSize = 2 * edgeSize;

    (* topViews = {True, False}; *)
    topViews = {True};

    For[viewIndex = 1, viewIndex <= Length[topViews], viewIndex++,
        topView = topViews[[viewIndex]];
        viewPoint = If[topView, {0, 0, 10}, {10, -10, 10}];

        graph = GraphPlot3D[
            edges,
            EdgeShapeFunction -> ({FaceForm[Gray], Cylinder[#1, edgeSize]} &), 
            VertexShapeFunction -> ({FaceForm[Hue[Total[#2]/(semiPerimeter + 1) ]], Sphere[#, nodeSize]} &),
            (* GraphLayout -> "SpringElectricalEmbedding", *)
            GraphLayout -> {"SpringElectricalEmbedding", "RepulsiveForcePower" -> -1},
            ViewPoint -> viewPoint
        ];


        outputFileName = "youngs_lattice" <> If[exportToPov, "_pov_", "_native_"] <> IntegerString[semiPerimeter] <> If[topView, "_top", "_side"] <> ".png";
        outputFileName = FileNameJoin[{imageFolder, outputFileName}];
        cropCommand = "mogrify -crop " <> IntegerString[imageSize[[2]]] <> "x" <> IntegerString[imageSize[[2]]] <> "+" <> IntegerString[(imageSize[[1]]-imageSize[[2]])/2] <> "+0 " <> outputFileName;

        If[exportToPov,
            If[FileExistsQ[outputFileName], DeleteFile[outputFileName]];
            POVRayRender[graph, 
                Method -> "Triangle", 
                OutputPath -> outputFileName, 
                ImageSize -> imageSize
                , RenderOptions -> "+A0.001 -J +UA"
            ];
            Run[cropCommand];
            Print[cropCommand];
            Print["saved file to " <> outputFileName]
            ,
            Export[outputFileName, graph];
        ];
    ];

];

