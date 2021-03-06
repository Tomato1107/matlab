% Simulation of two-arm manipulation.
% The cdts (Cooperative Dual Task-Space) class is used to simulate two kuka
% LWR manipulating a bucket (the bucket is not drawn).
function cdts_bucket_kuka()

    %% Basic definitions for the two-arm system
    kuka1 = KukaLwr4Robot.kinematics();    
    frame1 = 1 + DQ.E*0.5*DQ([0,-0.4,0,0]);
    kuka1.set_base_frame(frame1);
    kuka1.set_reference_frame(frame1);
    
    kuka2 = KukaLwr4Robot.kinematics();
    frame2 = 1 + DQ.E*0.5*DQ([0, 0.4,0,0]);
    kuka2.set_base_frame(frame2);
    kuka2.set_reference_frame(frame2);
    two_arms = DQ_CooperativeDualTaskSpace(kuka1, kuka2);


    %% Initial configurations
    q1_start = [-pi/2    pi/1.5   pi/4   pi/4   0  0  0]';
    q2_start = [-pi/2    pi/1.5  -pi/4   pi/4   0  0  0]';
    q =[ q1_start; q2_start];

    %% Task definitions for moving the bucket, which is already grasped.
    % The relative configuration between the hands must remain constant in
    % order to minimize internal forces.
    dqrd = two_arms.relative_pose(q);

    %Translate the bucket in the direction [-0.1,-0.1,-0,1] using the world
    %frame as reference, but maintain the orientation constant.
    dqad_ant =  two_arms.absolute_pose(q);
    dqad = (1+DQ.E*0.5*(-0.1*DQ.i-0.1*DQ.j-0.1*DQ.k)) * dqad_ant; 
    taskd=[vec8(dqad);vec8(dqrd)];


    %% Drawing the arms  
    opt={'noname'};
    plot(kuka1,q1_start',opt{:}); 
    hold on;
    plot(kuka2,q2_start',opt{:});
    plot(dqad,'scale',0.5);

    grid off;
    axis equal;
    axis ([-0.6,0.6,-0.2,0.8,-0.1,0.6])
    view (-179,27);
    xlabel('x');
    ylabel('y');


    %% Two-arm control
    epsilon = 0.01; %Stop condition
    nerror_ant = epsilon+1;
    err = 0;

    %The sweep motion (back and forth) will be performed twice
    while norm(nerror_ant - err) > epsilon

        %standard control law
        nerror_ant = err;
        jacob = [two_arms.absolute_pose_jacobian(q); ...
                 two_arms.relative_pose_jacobian(q)];
        taskm=  [vec8(two_arms.absolute_pose(q)); ...
                 vec8(two_arms.relative_pose(q))];
        err = taskd - taskm;
        q = q + pinv(jacob)*0.5*err;

        % Plot the arms    
        plot(kuka1,q(1:7)');    
        plot(kuka2,q(8:14)');
        %plot small coordinate systems such that one does not mistake with the desired absolute pose,
        %which is the big frame
        plot(two_arms.absolute_pose(q),'scale',0.1); 
        drawnow;
    end
end
