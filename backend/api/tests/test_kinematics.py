import unittest
import numpy as np
from api.utils.kinematics import KinematicAnalyzer

class TestKinematics(unittest.TestCase):
    def test_perfect_trace(self):
        """Test a perfect horizontal line against itself."""
        # Create a straight line from (0,0) to (100,0) over 100 steps
        start_t = 1600000000000 # Fake Epoch in ms
        x = np.linspace(0, 100, 100)
        y = np.zeros(100)
        # 1000 ms duration (1 second)
        t = np.linspace(start_t, start_t + 1000, 100)
        
        points = [{'x': xi, 'y': yi, 't': ti} for xi, yi, ti in zip(x, y, t)]
        
        # Target is the same
        target = points
        
        results = KinematicAnalyzer.analyze_stroke(points, target)
        
        # RMSE should be approx 0 (allow for resampling error)
        self.assertLess(results['rmse'], 0.1)
        # Jitter should be 0 (constant velocity), allowing for float precision with large Epochs
        self.assertLess(results['jitter'], 0.5)
        # Score should be high (Max is 100)
        self.assertGreater(results['score'], 95)

    def test_shaky_trace(self):
        """Test a shaky line against a straight target."""
        # Target: Straight line
        start_t = 1600000000000
        x_target = np.linspace(0, 100, 100)
        y_target = np.zeros(100)
        t_target = np.linspace(start_t, start_t + 1000, 100)
        target = [{'x': xi, 'y': yi} for xi, yi in zip(x_target, y_target)]
        
        # User: Straight line with random noise (shake)
        np.random.seed(42)
        y_shaky = np.random.normal(0, 5, 100) # StdDev 5 noise
        points = [{'x': xi, 'y': yi, 't': ti} for xi, yi, ti in zip(x_target, y_shaky, t_target)]
        
        results = KinematicAnalyzer.analyze_stroke(points, target)
        
        # RMSE should be significant (approx 5)
        self.assertGreater(results['rmse'], 2.0)
        # Jitter should be high due to random acceleration
        # With 1 sec duration and noise, acceleration is large
        self.assertGreater(results['jitter'], 10.0)
        # Score should be lower than perfect
        self.assertLess(results['score'], 90)

    def test_slow_trace(self):
        """Test velocity consistency logic."""
        # Not implementing complex velocity profile test yet, just simple structure check
        x = np.linspace(0, 100, 100)
        y = np.zeros(100)
        points = [{'x': xi, 'y': yi, 't': ti} for xi, yi, ti in zip(x, y, range(100))]
        
        results = KinematicAnalyzer.analyze_stroke(points)
        self.assertIsNotNone(results['velocity_consistency'])

if __name__ == '__main__':
    unittest.main()
