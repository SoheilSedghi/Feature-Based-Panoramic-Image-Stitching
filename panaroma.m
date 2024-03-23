% clear output of terminal and variables
clear
clf
clc 

% reading images
% add favourite images
image1 = imread('2.jpg');
image2 = imread('3.jpg');

% show original images
imshowpair(image1,image2,'montage');
pause(3);
clf

% convert to grayscale
gray_image1 = rgb2gray(image1) ;
gray_image2 = rgb2gray(image2) ;

imshowpair(gray_image1,gray_image2,'montage');
pause(3);
clf
% Initialize features for images 
%  SIFT feature points
points1 = detectSIFTFeatures(gray_image1);
points2 = detectSIFTFeatures(gray_image2);

% extracted feature vectors, also known as descriptors, and their corresponding locations, from a binary or intensity image.
[features1, valid_points1] = extractFeatures(gray_image1,points1);
[features2, valid_points2] = extractFeatures(gray_image2,points2);

% finding indices of matched feature points
index_pairs = matchFeatures(features1, features2, 'Unique', true);

% images match point locations
matched_points1 = valid_points1(index_pairs(:,1), :);
matched_points2 = valid_points2(index_pairs(:,2), :);

imshowpair(image1,image2,'montage');
hold on
%image 1 matched points draw
plot(matched_points1.Location(:,1), matched_points1.Location(:,2), 'ro', 'MarkerSize', 2);
hold on
%image 2 matched points draw
plot(matched_points2.Location(:,1)+size(image1,2), matched_points2.Location(:,2), 'ro', 'MarkerSize', 2);
hold on 
% image 1 and 2 matched line draw
for i = 1:size(matched_points2.Location(:,1))
    line([ matched_points1.Location(i,1)  matched_points2.Location(i,1)+size(image1,2)] ...
       , [ matched_points1.Location(i,2)  matched_points2.Location(i,2)], 'Color', 'red', 'LineWidth', 0.2);
end
pause(3)

% now we should estimate the geometric transformation, beacause we want to
% rotate and transite images to main image and make panorama.

% Initialize all the transformations to the identity matrix.
transformation(2) = projtform2d;

% Estimate the transformation between two images
transformation(2) = estgeotform2d(matched_points2 , matched_points1 , 'projective' , 'Confidence' , 99.9, 'MaxNumTrials' , 2000);


% now we should compute the panorama image size and decide the main image 
% we can skip this step for two images but for more images we should use
% it for better output so it is just a practice for now.

% Compute the output limits for each transformation.           
[xlim(1,:), ylim(1,:)] = outputLimits(transformation(1), [1 size(image1,2)], [1 size(image1,1)]);    
[xlim(2,:), ylim(2,:)] = outputLimits(transformation(2), [1 size(image2,2)], [1 size(image2,1)]);    


% A nicer panorama can be created by modifying the transformations such that
% the center of the scene is the least distorted.
% This is accomplished by inverting the transformation for the center image 
% and applying that transformation to all the others.
avgXLim = mean(xlim, 2);
[~,idx] = sort(avgXLim);
centerIdx = floor((numel(transformation)+1)/2);
% center image index
centerImageIdx = idx(centerIdx);

% Calculate the main image inverse transformation to transform others to
% main image.
Tinv = invert(transformation(centerImageIdx));
transformation(1).A = Tinv.A * transformation(1).A;
transformation(2).A = Tinv.A * transformation(2).A;

%Use the outputLimits method to compute the minimum and maximum output limits
% over all transformations. These values are used to automatically compute the size of the panorama
[xlim(1,:), ylim(1,:)] = outputLimits(transformation(1), [1 size(image1,2)], [1 size(image1,1)]);
[xlim(2,:), ylim(2,:)] = outputLimits(transformation(2), [1 size(image2,2)], [1 size(image2,1)]);

% maximum image size
max_image_size = max(size(image1),size(image2));


% Find the minimum and maximum output limits. 
xmin = min([1; xlim(:)]);
xmax = max([max_image_size(2); xlim(:)]);

ymin = min([1; ylim(:)]);
ymax = max([max_image_size(1); ylim(:)]);

% Width and height of panorama.
panorama_width  = round(xmax - xmin);
panorama_height = round(ymax - ymin);

% Initialize the black panorama to place images in that.
panorama = zeros([panorama_height panorama_width 3], 'like', image1);

% Combine images, overlay images, or highlight selected pixels
blender = vision.AlphaBlender('Operation' , 'Binary mask', 'MaskSource' , 'Input port');  

% Create a 2-D spatial reference object defining the size of the panorama.
x_limits = [xmin xmax];
y_limits = [ymin ymax];
panorama_view = imref2d([panorama_height panorama_width], x_limits, y_limits);

% Create the panorama.
  
   
% Transform Images into the panorama.
warped_image1 = imwarp(image1, transformation(1), 'OutputView', panorama_view);
warped_image2 = imwarp(image2, transformation(2), 'OutputView', panorama_view);


% Generate a binary mask.    
mask1 = imwarp(true(size(image1,1),size(image1,2)), transformation(1), 'OutputView', panorama_view);
mask2 = imwarp(true(size(image2,1),size(image2,2)), transformation(2), 'OutputView', panorama_view);

% Overlay the warpedImage onto the panorama.
panorama = step(blender, panorama, warped_image1, mask1);
panorama = step(blender, panorama, warped_image2, mask2);

clf
imshow(panorama)






