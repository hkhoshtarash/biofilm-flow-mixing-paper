import unittest
import numpy as np
from sigma_squared import sigma_squared

class SigmaTests(unittest.TestCase):
    def test_shared_mean_before_floor_and_region_split(self):
        speed=np.array([0.,1e-8,1e-4,1e-3]);bio=np.array([True,True,False,False])
        rows=sigma_squared(speed,biofilm_mask=bio)
        mean=speed.mean();u=np.maximum(speed/mean,1e-4)
        for r,m in zip(rows,[np.ones(4,dtype=bool),bio,~bio]):
            self.assertEqual(r['reference_mean_m_s'],mean)
            self.assertAlmostEqual(r['variance_ln_floored_normalized_speed'],np.log(u[m]).var())
            self.assertEqual(r['point_mass_count'],int(np.sum(speed[m]/mean<=1e-4)))

    def test_dimensional_floor_is_not_used(self):
        speed=np.array([1e-8,1e-5,1e-4,1e-3])
        r=sigma_squared(speed)[0]
        self.assertNotAlmostEqual(r['variance_ln_floored_normalized_speed'],np.log(np.maximum(speed,1e-4)).var())
        self.assertAlmostEqual(r['equivalent_dimensional_floor_m_s'],1e-4*speed.mean())

    def test_valid_fluid_zero_is_clamped(self):
        r=sigma_squared([0.,0.,1e-3],fluid_mask=np.array([False,True,True]))[0]
        self.assertEqual(r['n_total'],2);self.assertEqual(r['point_mass_count'],1)

    def test_exact_normalized_threshold(self):
        r=sigma_squared([1e-4,1.,1.9999])[0] # original mean = 1
        self.assertEqual(r['point_mass_count'],1)

    def test_vector_norm(self):
        a=sigma_squared([[3.,4.],[0.,0.]],component_axis=1)[0]
        b=sigma_squared([5.,0.])[0]
        self.assertEqual(a,b)

    def test_population_and_scale_invariance(self):
        x=np.array([0.,1e-5,2e-3,5e-3]);a=sigma_squared(x)[0];b=sigma_squared(x*100)[0]
        self.assertAlmostEqual(a['variance_ln_floored_normalized_speed'],b['variance_ln_floored_normalized_speed'])
        self.assertAlmostEqual(a['variance_ln_floored_normalized_speed'],np.var(np.log(np.maximum(x/x.mean(),1e-4)),ddof=0))

    def test_invalid_input(self):
        for x in [[0.,0.],[-1.,1.],[np.nan]]:
            with self.assertRaises(ValueError):sigma_squared(x)
        with self.assertRaises(ValueError):sigma_squared([1.,2.],fluid_mask=np.array([1,0]))
        with self.assertRaises(ValueError):sigma_squared([1.,2.],normalized_floor=0)

if __name__=='__main__':unittest.main()
