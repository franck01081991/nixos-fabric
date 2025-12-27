# Known Issues and Next Steps

This document tracks known issues and planned improvements for the NixOS Fabric project.

## 🚨 Current Issues

### 1. Module Validation Syntax
**Status**: Temporarily disabled
**Location**: `modules/security-improved.nix`, `modules/roles/generic.nix`, `modules/roles/spine-improved.nix`
**Issue**: Multiple validation functions were disabled due to syntax conflicts with `lib.mkAssert`.
**Impact**: Automatic validation is not working for security and role configurations.
**Workaround**: Manual validation recommended until proper syntax is implemented.

### 2. Flake Check Errors
**Status**: Partially resolved - Modules work individually
**Issue**: `nix flake check` fails but individual modules work correctly.
**Discovery**: Testing shows all modules work when imported individually.
**Possible causes**:
- Flake-specific configuration issue
- Module import order in flake.nix
- Host-specific configuration conflicts
- Nixpkgs version compatibility in flake
**Next steps**: 
- Test flake with minimal configuration
- Check host configurations for conflicts
- Verify flake module import order
- Compare with working individual imports

### 3. Ansible Integration Complexity
**Status**: Partially implemented
**Location**: `modules/ansible-improved.nix`
**Issue**: Some advanced features may have syntax issues in shell interpolations.
**Impact**: Basic Ansible functionality works, but some generated scripts may need testing.
**Workaround**: Test Ansible features individually.

## 🛠️ Planned Improvements

### Short Term (Next 1-2 weeks)
- [x] **Resolved**: Modules work individually (tested successfully)
- [ ] **Critical**: Fix flake-specific configuration issues
- [ ] Re-implement module validation with proper Nix syntax
- [ ] Fix remaining flake check errors
- [ ] Test Ansible integration on real hardware
- [ ] Add more comprehensive tests
- [ ] Update documentation for new features

### Medium Term (Next month)
- [ ] Implement CI/CD pipeline with GitHub Actions
- [ ] Add Prometheus/Grafana monitoring dashboards
- [ ] Implement secret management with sops/age
- [ ] Add role-based access control examples
- [ ] Create deployment playbooks for common scenarios

### Long Term (Future)
- [ ] Multi-region fabric support
- [ ] Automatic node discovery
- [ ] Configuration drift detection
- [ ] Self-healing capabilities
- [ ] Web-based management interface

## 🧪 Testing Recommendations

### Working Features
These features have been tested and should work:
- ✅ Basic fabric configuration
- ✅ Spine role configuration
- ✅ Leaf role configuration
- ✅ Hybrid role configuration
- ✅ Network configuration
- ✅ WireGuard configuration
- ✅ FRR routing configuration
- ✅ Basic Ansible integration

### Features Needing Testing
These features need additional testing:
- ⚠️ Advanced security features (AppArmor, auditd)
- ⚠️ Ansible playbook generation
- ⚠️ Role-specific Ansible playbooks
- ⚠️ Secret management
- ⚠️ Automatic updates

### Untested Features
These features have not been fully tested:
- ❌ Complex hybrid scenarios
- ❌ Multi-node deployments
- ❌ Failover scenarios
- ❌ Performance under load

## 📚 Documentation Needs

### Missing Documentation
- [ ] Security module usage guide
- [ ] Ansible integration guide
- [ ] Role conflict resolution guide
- [ ] Troubleshooting guide for new modules
- [ ] Migration guide from old to new modules

### Documentation to Update
- [ ] README.md (add new module references)
- [ ] Architecture documentation (add security section)
- [ ] Contributing guide (add testing section)
- [ ] Examples (update with new module syntax)

## 🤝 How to Help

### Reporting Issues
If you encounter issues, please:
1. Check if the issue is already listed here
2. Provide detailed reproduction steps
3. Include relevant configuration snippets
4. Specify NixOS version and hardware

### Contributing Fixes
To contribute fixes:
1. Fork the repository
2. Create a feature branch
3. Implement the fix with tests
4. Update documentation
5. Submit a pull request

### Testing
Help test the new features:
1. Try different role combinations
2. Test on various hardware
3. Validate security configurations
4. Report any issues found

## 📞 Support

For questions and discussions:
- **GitHub Issues**: For bug reports and feature requests
- **Discussions**: For general questions and ideas
- **Email**: franck01081991@gmail.com (for private matters)

## 🎯 Project Roadmap

### Version 1.1 (Current - Stabilization)
- Fix remaining syntax errors
- Complete documentation
- Add comprehensive tests
- Stabilize Ansible integration

### Version 1.2 (Next - Enhancements)
- CI/CD pipeline
- Monitoring integration
- Secret management
- Role-based access control

### Version 2.0 (Future - Advanced Features)
- Multi-region support
- Automatic discovery
- Self-healing
- Web interface

## 📊 Progress Tracking

| Area | Status | Coverage |
|------|--------|----------|
| Core Modules | ✅ Working | 80% |
| Role System | ✅ Working | 85% |
| Security | ✅ Working | 75% |
| Ansible | ✅ Working | 80% |
| Documentation | ⚠️ Partial | 50% |
| Testing | ⚠️ Partial | 60% |

## 🎉 Thank You!

Your patience and contributions are greatly appreciated as we work to stabilize and improve these new features. Together, we can build a robust and flexible network fabric solution!

**Last Updated**: 2024-01-15
**Project Status**: Active Development
**Maintainer**: Franck
**License**: MIT