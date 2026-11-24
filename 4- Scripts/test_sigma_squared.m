function test_sigma_squared()
speed=[0 1e-8 1e-4 1e-3]; bio=logical([1 1 0 0]);
rows=sigma_squared(speed,'BiofilmMask',bio);
u=max(speed/mean(speed),1e-4); masks={true(size(speed)),bio,~bio};
for i=1:numel(rows)
    assert(abs(rows(i).reference_mean_m_s-mean(speed))<1e-15);
    assert(abs(rows(i).variance_ln_floored_normalized_speed-var(log(u(masks{i})),1))<1e-12);
end
r=sigma_squared([0 0 1e-3],'FluidMask',logical([0 1 1]));
assert(r.n_total==2 && r.point_mass_count==1);
r=sigma_squared([1e-4 1 1.9999]); assert(r.point_mass_count==1);
a=sigma_squared([3 4;0 0],'ComponentDimension',2); b=sigma_squared([5;0]);
assert(abs(a.variance_ln_floored_normalized_speed-b.variance_ln_floored_normalized_speed)<1e-12);
fprintf('Normalized sigma-squared tests passed.\n');
end
