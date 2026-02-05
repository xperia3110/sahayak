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
        path = np.array([[p['x'], p['y']] for p in user_points])
        timestamps = np.array([p['t'] for p in user_points])
        
        # Normalize timestamps to start at 0 and convert to seconds if large
        if timestamps[0] > 1000000000:
             timestamps = (timestamps - timestamps[0]) / 1000.0
        else:
             timestamps = (timestamps - timestamps[0])

        # 1. Jitter (Tremor) - Acceleration changes
        dt = np.diff(timestamps)
        dt[dt == 0] = 1e-9
        
        displacement = np.diff(path, axis=0)
        velocity = displacement / dt[:, np.newaxis]
        
        # Acceleration
        if len(velocity) > 1:
            dv = np.diff(velocity, axis=0)
            dt_acc = dt[:-1]
            dt_acc[dt_acc == 0] = 1e-9
            acceleration = dv / dt_acc[:, np.newaxis]
            jitter_index = np.mean(np.linalg.norm(acceleration, axis=1))
        else:
            jitter_index = 0.0

        # 2. Velocity Consistency (CV)
        vel_magnitudes = np.linalg.norm(velocity, axis=1)
        mean_vel = np.mean(vel_magnitudes)
        if mean_vel > 0:
            velocity_consistency = np.std(vel_magnitudes) / mean_vel
        else:
            velocity_consistency = 0

        # 3. RMSE (Spatial Accuracy) - only if target provided
        rmse = 0.0
        if target_points and len(target_points) > 1:
            target = np.array([[p['x'], p['y']] for p in target_points])
            resampled_user = KinematicAnalyzer._resample_path(path, len(target))
            errors = np.linalg.norm(resampled_user - target, axis=1)
            rmse = np.sqrt(np.mean(errors**2))

        # 4. Final Score (0-100)
        # Normalize metrics and calculate score
        # Jitter: 0-500 typical range -> normalize to 0-50 deduction
        # Velocity CV: 0-2 typical range -> normalize to 0-30 deduction
        # RMSE: 0-100 typical range -> normalize to 0-20 deduction
        
        jitter_normalized = min(50, jitter_index * 0.1)  # Cap at 50
        velocity_normalized = min(30, velocity_consistency * 15)  # Cap at 30
        rmse_normalized = min(20, rmse * 0.2)  # Cap at 20
        
        total_deduction = jitter_normalized + velocity_normalized + rmse_normalized
        final_score = max(0, 100 - total_deduction)

        # Clamp to 0-100
        final_score = min(100, max(0, final_score))

        # Handle NaNs
        if np.isnan(final_score): final_score = 50.0
        if np.isnan(jitter_index): jitter_index = 0.0
        if np.isnan(velocity_consistency): velocity_consistency = 0.0

        return {
            'rmse': float(rmse),
            'jitter': float(jitter_index),
            'velocity_consistency': float(velocity_consistency),
            'score': round(float(final_score), 1)
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

        if total_dist == 0:
            return np.tile(path[0], (target_length, 1))

        # New evenly spaced distances
        new_dist = np.linspace(0, total_dist, target_length)

        # Interpolate x and y separately
        new_x = np.interp(new_dist, dist, path[:, 0])
        new_y = np.interp(new_dist, dist, path[:, 1])

        return np.column_stack((new_x, new_y))
