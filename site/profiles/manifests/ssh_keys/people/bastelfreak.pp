#
# @summary Configure key from bastelfreak from GitHubs in the authorized_keys file along with supplemental keys
#
# Configure key from bastelfreak from GitHubs in the authorized_keys file along with supplemental keys
#
class profiles::ssh_keys::people::bastelfreak {
  profiles::update_ssh_authorized_keys(['bastelfreak'])

  ssh_authorized_key {
    default:
      ensure => 'present',
      user   => 'root',
    ;
    'personal key 2021-07-02':
      type => 'ssh-ed25519',
      key  => 'AAAAC3NzaC1lZDI1NTE5AAAAIKO6DUyFoPn/euUQq+G7H49ESrT/28BhFbbjRl4wzPi7',
    ;
    'bastelfreak':
      type => 'ssh-ed25519',
      key  => 'AAAAC3NzaC1lZDI1NTE5AAAAIKC4uaKuYzMGK4jlTvPlbnMP9n+gdac65480/eDTMWRw',
    ;
    'bastelfreak-nb-c vox-pupuli-tasks 2021-08-30':
      type => 'ssh-ed25519',
      key  => 'AAAAC3NzaC1lZDI1NTE5AAAAIF7O2iuxjShCg0MNugyYjWTrjKmXd6tC7FIJPsejD8SB',
    ;
    'bastelfreak@bastelfreak-nb':
      type => 'ssh-rsa',
      key  => 'AAAAB3NzaC1yc2EAAAADAQABAAAEAQDEsooTj/ktA/0E1TA9wT3ekNNKGfdD1m9pOar4tgcQmXtafIeYBrmcSI7x1k4YkmvAInRpKTEKTGFq0GJg4/Q28lhO0lh52I2kg5xt6kEVWGGWvfHLXnZzRPuCBUKzy0cgTNr1mdo+bvSU08YFRAt3TAwID3uQ/AcQ4g+5xcFjFW4yDDdZMiBJKKPJB3EJmXTuMBBgD+Hd9nU9BYshqWnS6vubLIxHvLetisj62BRaI42p/9bMkqRxU/2uZQK1D9h4xTX18OZ6+Qo+xTOBBM3ZQ2vsKCiKD60b+bcEi2mNJLyzCe2fyusAeyjuEEcnE8gG0a30+eYurHZB6QUbkStVcrL555vN2ADGIXvFB3wvS52+2Y/Rx1bG+1B5LU7x/ykNeHiJnm9H25DbkmNH1RPmYr82u2U7Y0BMQQpxe3NB2+RKKFod4925ISXBxenQdZ/oGFK3VZnw0Xh9HjKiPAkHymP/jACQm4i8TEkWbBAzhlqOjOc5Exe6r/6dmJgTfjAJ2SvrzdQPil9JmmKH6w3DNTZrq9p6tuU2YpUtuAt4sy/IEnlBPVkHV8xovJjEEwY9DRfIgRbhGzlm1cgyyOaQVPUNyKnOK8LqQY/gBTMCnskx9F+65Ah5HjczCLki2u6eN8D6GZE7EqkrREUyh0meP9YPDQbSS+uI4j1WNu/qGEp2HuLGjdG8PbsM5MPhQOEsS7PNT+3NGUCcFVP/6n1QACMHhRBf7HU9HTKz9MjLPakq9q5V+bBs1DQ/t3Sziz32wseFZXHSCyfiCrM0PMp/KCuPLkEnTHOrV9QLCtgc4CV8ziWP483daRVJErEATBmvyvyJYylrsdqwuvj0UIcJuKJToU+cuBlFuykfCRLUQG7bfCGyeuf2188eHFAGkBRhU5GcAcWyRcj5kN7z/WcXTuSOC2emIYkoU/6ptoDdSmIxVbUxkdU5KQhnI2gN1l6CbMUIzsZ94hD20t1OEXUB7YL1JH8sD91jrfgRqWITs1tGHNol+dmXVSj/95lG1l+XxggnmdtP+lLSliiQrHrkURu7BuPV4IeHKxX2OaGFSGeCtC7eJhlc5BSNp6qjomZWhBMqaYGBvES5nG8UIOF9MsymxaBf7GWusYwwPTGa5zRBxHX6CRUOJaEx/d7vxB7GBcAwWoO37J3Ns801PZA+WCEqLv21gunMEgSVYX33jRDW3oZV/zO5a+bZlXksc27JMlqT6EXYnHRG/fUYaM7n1PqRxJ3boD7Z1EwJrlheCf83zQn+I4MDuB7tBN8xLx2MPLFse/wbRK1u1gW1qP3LVWqCoTevajtoUHeN3/JGvwnMLrygJck1HXLJEUfm4NN1m2Ag0vFvp+hJfRAoSUtT',
    ;
    'bastelfreak@basteles-bastelknecht.bastelfreak.org':
      type => 'ssh-rsa',
      key  => 'AAAAB3NzaC1yc2EAAAADAQABAAAEAQCs5EkKmqsL4eqUt09WTbvxAYYyChIw8Gok1Y7V15T42vezwRVlZ2h6F6vpa/AX+usukn4+dBFo+bJyD6Qy6EkWzaY96hGX3NziOxaCeueSXdc+b4xCEkfMOHJY1+pVm0cidQUozV/RWp/pQDzm9wUEMTYn6gB5XxDvAsGzUqKViLFeUKcZBsrbhbVvXCelgJWSd/k83KBfPtDHHcqpYJMuIWuGY9PPjwBkvokXRcWwZStsH60Q33sz+zsI1ujhnRxJRSBTn2BdfPHdiHDk6aO6SDglUqhdrq2fvIS5WOiptwSmvAAnG3+LprPiWrvppnBwuoGVOtwIspAVmCpyzamK/d7WoFMDTDPPhOmtIJyNqfNhPLhuIBlUjJLPgh4JjGnpMhnBmi0F+nciEfqYyK/KJYunfaYV6PRYUOKwEQ55nEpvq7tVKr2UWwLg7kzg+RvCBLFQ4qBkVUf4p44NRazLVMQDnSKXBH6dhwH3x4zHQ+sCsexXFAKfOGjnQGWBz2XvKFl/ml6aOHJnxqiBmpjmm34ULCYXhUi/dUlBV94+fsuO0qULei57F37LhMFeZocaxeD7+M4H2T6+cQCSTdxjr6Uj6BWK5FCHreQHgdL5Nq5kW/zCuoTtBoW9kp5fcn6ZjHCYprCThOIPRwINfznpuGg6LRyPnRgD2sVqSwLr2Rwt9zg3hS7ZBfXJYX28r1q4G+r7KuGLGEoLLVjl7RBWUUhXdF6GZ+6X5g6On9GBSDLpFHV0lC2NGKh+M6vcXJHeFh62dNOTMaC7H/JQcmB6G89y/OsT0S0v8q/k8i4Swaeh+iTNnv/tfC5ScDZY8gvUP2Zowd6HYwyvDHZ28vu812SAdWN99I4fIMGDpT5OLQGxArAV5VQeyRgaJHDX2umSdU+QN0fTaOL401ZDGOi9RQWuwldJC2D+MWTFhcM9yXtC6MOoM/b3F8nlbxhISvaHsrs37COEZQRxN7k3P9XMkmb/W2B5F2oEh4ggDlpJT+wtRHvKriGMtq1l23WZBsbcNEmxz7Uy/n4I8szuX2xATfmRf1z/GRk6IuudM/BfJBmQb77+ZFk9bN6w/es+EbsldatNdB3veJrL2bXVgB4CbsXx6M0sb3XAeJQq9AANY5vTsF3IY/weB84yTwaPLZyNsIJgy4AXG8xydbUNGeZExrddlpmPcE/AWkX9XqWGZPl/SLjdTMVUwhxRYn0FuhwZ1iQhZlwjuGcYFI8M2UJzIdTtDYAYMS8ekbNTwtex9EeLv63YrM2OMNqYchZTvyngifk6md/ZZhGxMnLvqe5zgh227jR+lAbGJ+gC1E4/jgQbiF93Ucp0eX8I9pzH0cc0GyDk5Fd4o+0CsKNsvLfx',
    ;
  }
}
