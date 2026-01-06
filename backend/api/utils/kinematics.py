import numpy as np

class KinematicAnalyzer:
    """
    Medical-grade Kinematic Analysis module for Dysgraphia screening.
    """

    @staticmethod
    def analyze_stroke(user_points, target_points=None):
        """
        Analyze a stroke path.
        
        Args:
            user_points (list): List of dicts {'x': float, 'y': float, 't': int/float}
            target_points (list, optional): List of dicts {'x': float, 'y': float} for reference.
            
        Returns:
            dict: {
                'rmse': float,
                'jitter': float,
                'velocity_consistency': float,
                'score': float
            }
        """
        if not user_points or len(user_points) < 2:
            return {
                'rmse': 0.0,
                'jitter': 0.0,
                'velocity_consistency': 0.0,
                'score': 0.0
            }

        # Convert to numpy arrays
        # Extract x, y, t
        # Ensure t is in seconds for physics calculations (input might be ms)
        path = np.array([[p['x'], p['y']] for p in user_points])
        timestamps = np.array([p['t'] for p in user_points])
        
        # Normalize timestamps to start at 0 and convert to seconds if large
        if timestamps[0] > 1000000000: # Assuming nanoseconds/milliseconds check
             timestamps = (timestamps - timestamps[0]) / 1000.0 # Convert ms to s
        else:
             timestamps = (timestamps - timestamps[0])

        # 1. Jitter (Tremor) - 2nd derivative of displacement (Acceleration) changes
        # Calculate Velocity (1st derivative)
        # Avoid division by zero
        dt = np.diff(timestamps)
        dt[dt == 0] = 1e-9 # Epsilon
        
        displacement = np.diff(path, axis=0)
        velocity = displacement / dt[:, np.newaxis]
        
        # Calculate Acceleration (2nd derivative)
        dv = np.diff(velocity, axis=0)
        # Adjust dt for acceleration (len is len(velocity)-1)
        dt_acc = dt[:-1]
        acceleration = dv / dt_acc[:, np.newaxis]
        
        # Jitter Metric: Mean Squared Jerk or just magnitude of acceleration changes
        # A simple robust jitter index is the mean magnitude of acceleration
        jitter_index = np.mean(np.linalg.norm(acceleration, axis=1))

        # 2. Velocity Consistency (Bradykinesia check)
        # CV of velocity (Coefficient of Variation) = StdDev / Mean
        vel_magnitudes = np.linalg.norm(velocity, axis=1)
        mean_vel = np.mean(vel_magnitudes)
        if mean_vel > 0:
            velocity_consistency = np.std(vel_magnitudes) / mean_vel
        else:
            velocity_consistency = 0

        # 3. RMSE (Spatial Accuracy)
        rmse = 0.0
        if target_points:
            target = np.array([[p['x'], p['y']] for p in target_points])
            # Simple resampling to match lengths (Linear Interpolation)
            if len(target) > 1:
                # Resample user path to match target length for direct comparison
                # This is a simplification; DTW is better but expensive for this context
                resampled_user = KinematicAnalyzer._resample_path(path, len(target))
                
                # Calculate Euclidean distance between corresponding points
                errors = np.linalg.norm(resampled_user - target, axis=1)
                rmse = np.sqrt(np.mean(errors**2))

        # 4. Final Score (0-100)
        # Simple heuristic weights
        # Lower RMSE -> Higher Score
        # Lower Jitter -> Higher Score
        # Lower Velocity Variability -> Higher Score (usually, though dysgraphia can be halting)
        
        # Normalize metrics to 0-1 scale ideally, here using approximate thresholds
        # Example thresholds (need calibration):
        # RMSE: 0 (Good) -> 50 (Bad)
        # Jitter: 0 (Smooth) -> 1000 (Shaky)
        
        score_deduction = (rmse * 0.5) + (jitter_index * 0.05) + (velocity_consistency * 10)
        final_score = max(0, 100 - score_deduction)

        # Handle NaNs
        if np.isnan(final_score): final_score = 0

        return {
            'rmse': float(rmse),
            'jitter': float(jitter_index) if not np.isnan(jitter_index) else 0.0,
            'velocity_consistency': float(velocity_consistency) if not np.isnan(velocity_consistency) else 0.0,
            'score': float(final_score)
        }

    @staticmethod
    def _resample_path(path, target_length):
        """
        Resample a 2D path to a specific number of points using linear interpolation.
        """
        if len(path) == 0: return np.zeros((target_length, 2))
        if len(path) == 1: return np.tile(path[0], (target_length, 1))

        # Calculate cumulative distance along the path
        dist = np.cumsum(np.sqrt(np.sum(np.diff(path, axis=0)**2, axis=1)))
        dist = np.insert(dist, 0, 0)
        total_dist = dist[-1]

        # New evenly spaced distances
        new_dist = np.linspace(0, total_dist, target_length)

        # Interpolate x and y separately
        new_x = np.interp(new_dist, dist, path[:, 0])
        new_y = np.interp(new_dist, dist, path[:, 1])

        return np.column_stack((new_x, new_y))
